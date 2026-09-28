import 'package:flutter/foundation.dart';

import '../../../discovery/domain/entities/money.dart';
import '../../../reservation/domain/entities/reservation.dart';

/// Everything the mobile app can supply to request a deposit hold on a
/// reservation.
///
/// The approved guest-facing backend `POST
/// /api/v1/guest/reservations/{reservation}/payment/hold`
/// (`InitiateGuestPaymentHoldRequest`, `GuestPaymentController::hold`) takes no
/// body — it derives the deposit amount itself from
/// `config('guest_booking.deposit')`, ownership-checked against the calling
/// guest; the idempotency key travels as the `Idempotency-Key` HTTP header. A
/// separate staff/dashboard-scoped endpoint
/// (`POST /api/v1/reservations/{reservation}/payment/hold`, `PaymentPolicy`)
/// takes an explicit `amount`/`currency`. This request only carries what the
/// guest app knows: the [reservationId] and the [amount] captured from the
/// authoritative reservation price snapshot, for display and idempotency-key
/// derivation — the guest endpoint itself ignores any amount the client sends.
///
/// No card data, CVV, PIN or provider credential is ever part of this request:
/// the MVP dummy provider needs none, and a real integration would collect
/// those through the provider's own SDK/redirect, never through our API body
/// (mobile/docs/architecture.md §8).
@immutable
class PaymentHoldRequest {
  const PaymentHoldRequest({
    required this.reservationId,
    required this.amount,
  });

  /// Builds the hold request from an authoritative [Reservation]: the hold is
  /// the server-computed deposit (`hotel.deposit_amount` — the hotel's
  /// `deposit_percentage` of the price snapshot), in its currency. The guest
  /// endpoint derives the amount itself; this mirrors it for the dummy source.
  /// Only when the deposit is unknown does it fall back to the snapshot.
  factory PaymentHoldRequest.forReservation(Reservation reservation) {
    return PaymentHoldRequest(
      reservationId: reservation.id,
      amount: reservation.depositAmount ?? reservation.priceSnapshot,
    );
  }

  final String reservationId;
  final Money amount;

  /// The `amount` body field: a decimal string with two fractional digits, the
  /// shape `StorePaymentHoldRequest` validates (`/^\d{1,10}(\.\d{1,2})?$/`).
  String get amountWire => amount.amount.toStringAsFixed(2);

  /// The `currency` body field: a 3-letter ISO-style code.
  String get currencyWire => amount.currency;

  /// A stable idempotency key for this exact request — used as the
  /// `Idempotency-Key` header and to dedupe repeated submits. No time
  /// component, no randomness, so a widget rebuild yields the identical key.
  String get idempotencyKey => <String>[
        'pay',
        reservationId,
        amount.amount.toString(),
        amount.currency,
      ].join(':');

  @override
  bool operator ==(Object other) =>
      other is PaymentHoldRequest &&
      other.reservationId == reservationId &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(reservationId, amount);

  @override
  String toString() => 'PaymentHoldRequest($idempotencyKey)';
}
