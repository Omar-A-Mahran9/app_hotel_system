// Data-transfer models for the payment feature.
//
// `PaymentModel` mirrors the safe Laravel `PaymentResource` shape (id,
// reservation_id, hotel_id, status, amount, currency, hold_expires_at,
// created_at, updated_at). `PaymentHoldPayload.toJson` mirrors the documented
// `StorePaymentHoldRequest` body (`amount`, `currency`) — the idempotency key is
// an HTTP header, never a body field, and no card/credential data exists here.

import '../../../discovery/domain/entities/money.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/entities/payment_status.dart';

typedef Json = Map<String, Object?>;

/// The request body for `POST /reservations/{reservation}/payment/hold`, as far
/// as the documented contract goes. `amount` is a two-decimal string; the
/// `Idempotency-Key` header is carried separately by the data source.
class PaymentHoldPayload {
  const PaymentHoldPayload({required this.amount, required this.currency});

  factory PaymentHoldPayload.fromRequest(PaymentHoldRequest r) =>
      PaymentHoldPayload(amount: r.amountWire, currency: r.currencyWire);

  final String amount;
  final String currency;

  Json toJson() => <String, Object?>{
        'amount': amount,
        'currency': currency,
      };
}

/// Parsed `PaymentResource`.
class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.reservationId,
    required this.hotelId,
    required this.status,
    required this.amount,
    required this.currency,
    required this.createdAt,
    this.holdExpiresAt,
    this.updatedAt,
    this.depositRequired = true,
  });

  /// The backend's answer for a 0% deposit hotel: confirmed, nothing held.
  factory PaymentModel.notRequired(String reservationId) => PaymentModel(
        id: '',
        reservationId: reservationId,
        hotelId: '',
        status: PaymentStatus.notStarted,
        amount: 0,
        currency: Money.fallbackCurrency,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        depositRequired: false,
      );

  factory PaymentModel.fromJson(Json json) {
    return PaymentModel(
      id: json['id'] == null ? '' : '${json['id']}',
      reservationId: '${json['reservation_id']}',
      hotelId: '${json['hotel_id']}',
      status: PaymentStatus.fromWire(
        (json['status'] as String?) ?? PaymentStatus.notStarted.wireValue,
      ),
      amount: _amount(json['amount']),
      currency: (json['currency'] as String?) ?? Money.fallbackCurrency,
      holdExpiresAt: _dateOrNull(json['hold_expires_at']),
      createdAt: _dateOrNull(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: _dateOrNull(json['updated_at']),
    );
  }

  final String id;
  final String reservationId;
  final String hotelId;
  final PaymentStatus status;
  final num amount;
  final String currency;
  final DateTime? holdExpiresAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool depositRequired;

  Payment toEntity() => Payment(
        id: id,
        reservationId: reservationId,
        hotelId: hotelId,
        status: status,
        amount: Money(amount: amount, currency: currency),
        holdExpiresAt: holdExpiresAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        depositRequired: depositRequired,
      );

  /// The Laravel resource serialises `amount` as a `decimal:2` string
  /// (e.g. `"945.00"`). The app's [Money] is whole currency units.
  static num _amount(Object? raw) => Money.parseAmount(raw);

  static DateTime? _dateOrNull(Object? raw) {
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }
}
