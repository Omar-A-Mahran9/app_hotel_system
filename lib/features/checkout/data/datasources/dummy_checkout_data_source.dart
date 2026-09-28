import '../../../../core/data/data_source.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../discovery/domain/entities/money.dart';
import '../../../payment/domain/entities/payment_status.dart';
import '../../domain/entities/checkout.dart';
import '../../domain/entities/checkout_status.dart';
import '../../domain/entities/folio.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/checkout_repository.dart';
import 'checkout_data_source.dart';

/// A deterministic settlement scenario, chosen purely from the reservation id.
enum DummySettlementScenario {
  /// Settlement succeeds (or nothing was owed) → checkout completes.
  settles,

  /// Settlement fails on the first attempt; a retry completes.
  failsThenSettles,

  /// Settlement returns pending — checkout stays `awaiting_settlement`.
  staysPending,
}

/// Deterministic, offline checkout + invoice source used while no guest-facing
/// checkout/invoice contract is approved. Implements **both** data contracts so
/// one instance shares the checkout/invoice state.
///
/// Guarantees required by the phase brief:
/// * no network, no timers, no randomness, no `DateTime.now()` branching (a
///   `clock` is injected for display timestamps only);
/// * every money value comes from the deterministic folio it builds — the folio
///   totals are computed **here once** in the same shape the backend sends, and
///   the app only ever displays them (never re-derives a settlement amount, a
///   subtotal, or an outstanding balance);
/// * `performCheckout` is idempotent for a non-failed result (a repeat replays
///   the completed checkout); a `settlement_failed` result is not cached so a
///   genuine retry re-attempts and (per [scenarioFor]) then completes;
/// * the invoice is available only after checkout completes (mirrors the
///   backend 404 before then).
///
/// [failWith] is a test seam.
class DummyCheckoutDataSource
    implements CheckoutDataSource, InvoiceDataSource, DummyDataSource {
  DummyCheckoutDataSource({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, CheckoutResult> _resultByKey = <String, CheckoutResult>{};
  final Map<String, Invoice> _invoiceByReservation = <String, Invoice>{};
  final Map<String, int> _attempts = <String, int>{};

  Object? failWith;

  static DummySettlementScenario scenarioFor(String reservationId) {
    switch (_fnv1a(reservationId) % 3) {
      case 0:
        return DummySettlementScenario.settles;
      case 1:
        return DummySettlementScenario.failsThenSettles;
      default:
        return DummySettlementScenario.staysPending;
    }
  }

  // ── Folio ──────────────────────────────────────────────────────────

  @override
  Future<Folio> fetchFolio(FolioContext context) async {
    if (failWith != null) throw failWith!;
    return _folio(context);
  }

  Folio _folio(FolioContext ctx) {
    final String cur = ctx.currency;
    final DateTime charged = _clock();
    final List<FolioCharge> charges = <FolioCharge>[
      FolioCharge(
        id: 'acc-${ctx.reservationId}',
        sourceType: 'accommodation',
        description: 'Accommodation',
        quantity: 1,
        unitAmount: Money(amount: ctx.accommodationAmount, currency: cur),
        totalAmount: Money(amount: ctx.accommodationAmount, currency: cur),
        status: 'posted',
        chargedAt: charged,
      ),
      ..._serviceCharges(ctx.reservationId, cur, charged),
    ];

    // Deposit holds are authorizations, not captured money — payments_total
    // counts captured/settled only, so it is 0 until checkout settles.
    final num chargesTotal =
        charges.fold<num>(0, (num sum, FolioCharge c) => sum + c.totalAmount.amount);

    return Folio(
      reservationId: ctx.reservationId,
      currency: cur,
      charges: charges,
      chargesTotal: Money(amount: chargesTotal, currency: cur),
      paymentsTotal: Money(amount: 0, currency: cur),
      outstandingTotal: Money(amount: chargesTotal, currency: cur),
    );
  }

  List<FolioCharge> _serviceCharges(
      String reservationId, String currency, DateTime charged) {
    final int hash = _fnv1a(reservationId);
    final List<int> amounts = switch (hash % 3) {
      0 => const <int>[],
      1 => const <int>[45],
      _ => const <int>[45, 120],
    };
    return <FolioCharge>[
      for (int i = 0; i < amounts.length; i++)
        FolioCharge(
          id: 'svc-$reservationId-$i',
          sourceType: 'service_order',
          description: i == 0 ? 'Service charge' : 'Room service',
          quantity: 1,
          unitAmount: Money(amount: amounts[i], currency: currency),
          totalAmount: Money(amount: amounts[i], currency: currency),
          status: 'posted',
          chargedAt: charged,
        ),
    ];
  }

  // ── Checkout ───────────────────────────────────────────────────────

  @override
  Future<CheckoutResult> performCheckout(
    CheckoutRequest request,
    FolioContext context,
  ) async {
    if (failWith != null) throw failWith!;

    final CheckoutResult? cached = _resultByKey[request.idempotencyKey];
    if (cached != null &&
        cached.checkout.status != CheckoutStatus.settlementFailed) {
      return cached;
    }

    final int attempts = (_attempts[request.reservationId] ?? 0) + 1;
    _attempts[request.reservationId] = attempts;

    final Folio folio = _folio(context);
    final CheckoutStatus status =
        _resolve(request.reservationId, attempts);
    final DateTime now = _clock();

    final Checkout checkout = Checkout(
      reservationId: request.reservationId,
      status: status,
      chargesTotal: folio.chargesTotal,
      paymentsTotal: folio.paymentsTotal,
      outstandingTotal: status == CheckoutStatus.completed
          ? Money(amount: 0, currency: folio.currency)
          : folio.outstandingTotal,
      currency: folio.currency,
      startedAt: now,
      completedAt: status == CheckoutStatus.completed ? now : null,
    );

    final bool owed = folio.outstandingTotal.amount > 0;
    final PaymentStatus? settlement = !owed
        ? null
        : switch (status) {
            CheckoutStatus.completed => PaymentStatus.settled,
            CheckoutStatus.settlementFailed => PaymentStatus.captureFailed,
            _ => PaymentStatus.captureRequested,
          };

    InvoiceRef? invoiceRef;
    if (status == CheckoutStatus.completed) {
      final Invoice invoice = _issueInvoice(request.reservationId, folio, now);
      _invoiceByReservation[request.reservationId] = invoice;
      invoiceRef = InvoiceRef(
        id: invoice.id,
        invoiceNumber: invoice.invoiceNumber,
        status: invoice.status,
        issuedAt: invoice.issuedAt,
      );
    }

    final CheckoutResult result = CheckoutResult.of(
      checkout,
      settlementStatus: settlement,
      invoice: invoiceRef,
    );
    if (status != CheckoutStatus.settlementFailed) {
      _resultByKey[request.idempotencyKey] = result;
    }
    return result;
  }

  CheckoutStatus _resolve(String reservationId, int attempts) {
    return switch (scenarioFor(reservationId)) {
      DummySettlementScenario.settles => CheckoutStatus.completed,
      DummySettlementScenario.failsThenSettles => attempts <= 1
          ? CheckoutStatus.settlementFailed
          : CheckoutStatus.completed,
      DummySettlementScenario.staysPending => CheckoutStatus.awaitingSettlement,
    };
  }

  // ── Invoice ────────────────────────────────────────────────────────

  @override
  Future<Invoice> fetchInvoice(String reservationId) async {
    if (failWith != null) throw failWith!;
    final Invoice? invoice = _invoiceByReservation[reservationId];
    if (invoice == null) {
      throw NotFoundException('No invoice for reservation "$reservationId"');
    }
    return invoice;
  }

  Invoice _issueInvoice(String reservationId, Folio folio, DateTime now) {
    final int hash = _fnv1a(reservationId);
    final String number =
        'INV-${1000 + (hash % 9000)}-${(hash % 90) + 10}';
    return Invoice(
      id: '${5000 + (hash % 5000)}',
      reservationId: reservationId,
      invoiceNumber: number,
      status: InvoiceStatus.issued,
      currency: folio.currency,
      subtotal: folio.chargesTotal,
      paymentsTotal: folio.chargesTotal,
      outstandingTotal: Money(amount: 0, currency: folio.currency),
      issuedAt: now,
      items: <InvoiceItem>[
        for (final FolioCharge c in folio.postedCharges)
          InvoiceItem(
            sourceType: c.sourceType,
            description: c.description,
            quantity: c.quantity,
            unitAmount: c.unitAmount,
            totalAmount: c.totalAmount,
          ),
      ],
    );
  }

  static int _fnv1a(String value) {
    int hash = 0x811c9dc5;
    for (final int unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
