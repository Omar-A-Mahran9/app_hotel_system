// Data-transfer models for the checkout feature.
//
// Shapes mirror the safe Laravel resources exactly: `FolioResource` /
// `FolioChargeResource`, `CheckoutResource`, `InvoiceResource` /
// `InvoiceItemResource`. Money on the wire is a `decimal:2` string; the app's
// [Money] is whole units. No client-side arithmetic on any total.

import '../../../discovery/domain/entities/money.dart';
import '../../../payment/domain/entities/payment_status.dart';
import '../../domain/entities/checkout.dart';
import '../../domain/entities/checkout_status.dart';
import '../../domain/entities/folio.dart';
import '../../domain/entities/invoice.dart';

typedef Json = Map<String, Object?>;

num _money(Object? raw) => Money.parseAmount(raw);

DateTime? _dateOrNull(Object? raw) {
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  return null;
}

class FolioChargeModel {
  const FolioChargeModel(this._json);
  final Json _json;

  FolioCharge toEntity(String currency) {
    final String cur = (_json['currency'] as String?) ?? currency;
    return FolioCharge(
      id: '${_json['id']}',
      sourceType: (_json['source_type'] as String?) ?? 'service_order',
      description: (_json['description'] as String?) ?? '',
      quantity: (_json['quantity'] as num?)?.toInt() ?? 1,
      unitAmount: Money(amount: _money(_json['unit_amount']), currency: cur),
      totalAmount: Money(amount: _money(_json['total_amount']), currency: cur),
      status: (_json['status'] as String?) ?? 'posted',
      chargedAt: _dateOrNull(_json['charged_at']),
    );
  }
}

class FolioModel {
  const FolioModel(this._json);
  final Json _json;

  Folio toEntity() {
    final Json totals = (_json['totals'] as Json?) ?? const <String, Object?>{};
    final String currency = (_json['currency'] as String?) ?? Money.fallbackCurrency;
    final List<Object?> charges =
        (_json['charges'] as List<Object?>?) ?? const <Object?>[];
    final Json reservation =
        (_json['reservation'] as Json?) ?? const <String, Object?>{};
    return Folio(
      reservationId: '${reservation['id']}',
      currency: currency,
      charges: charges
          .whereType<Json>()
          .map((Json j) => FolioChargeModel(j).toEntity(currency))
          .toList(growable: false),
      chargesTotal:
          Money(amount: _money(totals['charges_total']), currency: currency),
      paymentsTotal:
          Money(amount: _money(totals['payments_total']), currency: currency),
      outstandingTotal: Money(
          amount: _money(totals['outstanding_total']), currency: currency),
    );
  }
}

class CheckoutResultModel {
  const CheckoutResultModel(this._json);
  final Json _json;

  CheckoutResult toEntity() {
    final Json checkout =
        (_json['checkout'] as Json?) ?? const <String, Object?>{};
    final Json reservation =
        (_json['reservation'] as Json?) ?? const <String, Object?>{};
    final Json totals =
        (_json['totals'] as Json?) ?? const <String, Object?>{};
    final String currency = (_json['currency'] as String?) ?? Money.fallbackCurrency;
    final Json? payment = _json['payment'] as Json?;
    final Json? invoice = _json['invoice'] as Json?;

    final Checkout c = Checkout(
      reservationId: '${reservation['id']}',
      status: CheckoutStatus.fromWire(
        (checkout['status'] as String?) ?? CheckoutStatus.inProgress.wireValue,
      ),
      chargesTotal:
          Money(amount: _money(totals['charges_total']), currency: currency),
      paymentsTotal:
          Money(amount: _money(totals['payments_total']), currency: currency),
      outstandingTotal: Money(
          amount: _money(totals['outstanding_total']), currency: currency),
      currency: currency,
      startedAt: _dateOrNull(checkout['started_at']),
      completedAt: _dateOrNull(checkout['completed_at']),
    );

    return CheckoutResult.of(
      c,
      settlementStatus: payment == null
          ? null
          : PaymentStatus.fromWire((payment['status'] as String?) ?? ''),
      invoice: invoice == null
          ? null
          : InvoiceRef(
              id: '${invoice['id']}',
              invoiceNumber: (invoice['invoice_number'] as String?) ?? '',
              status: InvoiceStatus.fromWire(invoice['status'] as String?),
              issuedAt: _dateOrNull(invoice['issued_at']),
            ),
    );
  }
}

class InvoiceItemModel {
  const InvoiceItemModel(this._json);
  final Json _json;

  InvoiceItem toEntity(String currency) => InvoiceItem(
        sourceType: _json['source_type'] as String?,
        description: (_json['description'] as String?) ?? '',
        quantity: (_json['quantity'] as num?)?.toInt() ?? 1,
        unitAmount:
            Money(amount: _money(_json['unit_amount']), currency: currency),
        totalAmount:
            Money(amount: _money(_json['total_amount']), currency: currency),
      );
}

class InvoiceModel {
  const InvoiceModel(this._json);
  final Json _json;

  Invoice toEntity() {
    final String currency = (_json['currency'] as String?) ?? Money.fallbackCurrency;
    final List<Object?> items =
        (_json['items'] as List<Object?>?) ?? const <Object?>[];
    return Invoice(
      id: '${_json['id']}',
      reservationId: '${_json['reservation_id']}',
      invoiceNumber: (_json['invoice_number'] as String?) ?? '',
      status: InvoiceStatus.fromWire(_json['status'] as String?),
      currency: currency,
      subtotal: Money(amount: _money(_json['subtotal']), currency: currency),
      paymentsTotal:
          Money(amount: _money(_json['payments_total']), currency: currency),
      outstandingTotal: Money(
          amount: _money(_json['outstanding_total']), currency: currency),
      issuedAt: _dateOrNull(_json['issued_at']),
      items: items
          .whereType<Json>()
          .map((Json j) => InvoiceItemModel(j).toEntity(currency))
          .toList(growable: false),
    );
  }
}
