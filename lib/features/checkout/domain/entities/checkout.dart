import 'package:flutter/foundation.dart';

import '../../../discovery/domain/entities/money.dart';
import '../../../payment/domain/entities/payment_status.dart';
import '../../../reservation/domain/entities/reservation.dart';
import 'checkout_status.dart';

/// A checkout process record, mirroring the safe fields of the Laravel
/// `CheckoutResource` (`checkout.status`, `checkout.started_at`,
/// `checkout.completed_at`, `totals`, `currency`).
///
/// ACCOUNTING: [chargesTotal] / [paymentsTotal] / [outstandingTotal] are the
/// **backend snapshot**. The app never computes them.
@immutable
class Checkout {
  const Checkout({
    required this.reservationId,
    required this.status,
    required this.chargesTotal,
    required this.paymentsTotal,
    required this.outstandingTotal,
    required this.currency,
    this.startedAt,
    this.completedAt,
  });

  final String reservationId;
  final CheckoutStatus status;
  final Money chargesTotal;
  final Money paymentsTotal;
  final Money outstandingTotal;
  final String currency;
  final DateTime? startedAt;
  final DateTime? completedAt;

  bool get isComplete => status.isComplete;

  @override
  bool operator ==(Object other) =>
      other is Checkout &&
      other.reservationId == reservationId &&
      other.status == status &&
      other.chargesTotal == chargesTotal &&
      other.paymentsTotal == paymentsTotal &&
      other.outstandingTotal == outstandingTotal &&
      other.currency == currency &&
      other.startedAt == startedAt &&
      other.completedAt == completedAt;

  @override
  int get hashCode => Object.hash(reservationId, status, chargesTotal,
      paymentsTotal, outstandingTotal, currency, startedAt, completedAt);

  @override
  String toString() => 'Checkout($reservationId, ${status.wireValue})';
}

/// The compact invoice reference the checkout response carries (`invoice.id`,
/// `invoice.invoice_number`, `invoice.status`, `invoice.issued_at`). The full
/// line-item invoice is fetched separately.
@immutable
class InvoiceRef {
  const InvoiceRef({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    this.issuedAt,
  });

  final String id;
  final String invoiceNumber;
  final InvoiceStatus status;
  final DateTime? issuedAt;

  @override
  bool operator ==(Object other) =>
      other is InvoiceRef &&
      other.id == id &&
      other.invoiceNumber == invoiceNumber &&
      other.status == status &&
      other.issuedAt == issuedAt;

  @override
  int get hashCode => Object.hash(id, invoiceNumber, status, issuedAt);
}

/// Everything the mobile app can supply to perform checkout.
///
/// The approved backend `POST /api/v1/reservations/{reservation}/checkout`
/// (`PerformCheckoutRequest`) carries **no body fields** — the settlement
/// amount is always computed server-side from the authoritative folio, and the
/// idempotency key is the `Idempotency-Key` header. That endpoint is
/// staff/dashboard-scoped (`ReservationService::findAccessibleBy` +
/// `CheckoutPolicy`), so this request only carries the reservation id.
@immutable
class CheckoutRequest {
  const CheckoutRequest({required this.reservationId});

  factory CheckoutRequest.forReservation(Reservation reservation) =>
      CheckoutRequest(reservationId: reservation.id);

  final String reservationId;

  /// Stable idempotency key — used as the `Idempotency-Key` header (shared with
  /// the final-settlement transaction) and to dedupe repeated submits. No time
  /// component, no randomness.
  String get idempotencyKey => 'checkout:$reservationId';

  @override
  bool operator ==(Object other) =>
      other is CheckoutRequest && other.reservationId == reservationId;

  @override
  int get hashCode => reservationId.hashCode;

  @override
  String toString() => 'CheckoutRequest($idempotencyKey)';
}

/// The safe, client-visible outcome of a checkout attempt — mirrors the
/// branches of `CheckoutController::store` (200 completed / 422 settlement
/// pending / 422 settlement failed).
enum CheckoutOutcome {
  completed,
  settlementPending,
  settlementFailed;

  static CheckoutOutcome fromStatus(CheckoutStatus status) => switch (status) {
        CheckoutStatus.completed => CheckoutOutcome.completed,
        CheckoutStatus.awaitingSettlement => CheckoutOutcome.settlementPending,
        CheckoutStatus.settlementFailed => CheckoutOutcome.settlementFailed,
        CheckoutStatus.inProgress => CheckoutOutcome.settlementPending,
      };

  bool get isSuccess => this == CheckoutOutcome.completed;
  bool get isRetryable => this == CheckoutOutcome.settlementFailed;
}

/// The outcome of a checkout attempt, mirroring `CheckoutResource`
/// (`checkout`, `payment`, `invoice`).
@immutable
class CheckoutResult {
  const CheckoutResult({
    required this.checkout,
    required this.outcome,
    this.settlementStatus,
    this.invoice,
  });

  factory CheckoutResult.of(
    Checkout checkout, {
    PaymentStatus? settlementStatus,
    InvoiceRef? invoice,
  }) =>
      CheckoutResult(
        checkout: checkout,
        outcome: CheckoutOutcome.fromStatus(checkout.status),
        settlementStatus: settlementStatus,
        invoice: invoice,
      );

  final Checkout checkout;
  final CheckoutOutcome outcome;

  /// The final-settlement payment status (`CheckoutResource.payment.status`),
  /// when a settlement was required. Null when nothing was owed.
  final PaymentStatus? settlementStatus;

  /// The issued invoice reference, present once checkout completes.
  final InvoiceRef? invoice;

  @override
  bool operator ==(Object other) =>
      other is CheckoutResult &&
      other.checkout == checkout &&
      other.outcome == outcome &&
      other.settlementStatus == settlementStatus &&
      other.invoice == invoice;

  @override
  int get hashCode =>
      Object.hash(checkout, outcome, settlementStatus, invoice);
}
