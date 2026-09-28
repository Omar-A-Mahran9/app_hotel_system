import 'package:flutter/foundation.dart';

import '../../../discovery/domain/entities/money.dart';
import 'payment_status.dart';

/// A payment as the guest app knows it.
///
/// Mirrors the safe fields of the Laravel `PaymentResource` (`id`,
/// `reservation_id`, `hotel_id`, `status`, `amount`, `currency`,
/// `hold_expires_at`, `created_at`, `updated_at`). Provider references,
/// transaction rows, webhook data and idempotency keys are deliberately absent
/// there and here — the client only ever sees application-level state
/// (mobile/docs/architecture.md §8).
///
/// Laravel stays authoritative for [status] and [amount]; the app never
/// transitions a payment itself.
@immutable
class Payment {
  const Payment({
    required this.id,
    required this.reservationId,
    required this.hotelId,
    required this.status,
    required this.amount,
    required this.createdAt,
    this.holdExpiresAt,
    this.updatedAt,
    this.depositRequired = true,
  });

  /// The backend primary key (as a string at the mobile boundary). Empty for a
  /// reservation that has no payment record yet ([PaymentStatus.notStarted]).
  final String id;

  final String reservationId;
  final String hotelId;
  final PaymentStatus status;

  /// The authoritative amount the backend recorded for this payment.
  final Money amount;

  /// When an active authorization hold lapses, when the backend reports one.
  final DateTime? holdExpiresAt;

  final DateTime createdAt;
  final DateTime? updatedAt;

  /// False when the hotel takes no deposit (0%): the backend confirmed the
  /// reservation without a hold (`meta.deposit_required: false`).
  final bool depositRequired;

  bool get exists => id.isNotEmpty;

  /// A synthetic "no payment yet" record for a reservation, so the review
  /// screen has something to render before the first hold.
  factory Payment.none({
    required String reservationId,
    required String hotelId,
    required Money amount,
  }) {
    return Payment(
      id: '',
      reservationId: reservationId,
      hotelId: hotelId,
      status: PaymentStatus.notStarted,
      amount: amount,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Payment &&
      other.id == id &&
      other.reservationId == reservationId &&
      other.hotelId == hotelId &&
      other.status == status &&
      other.amount == amount &&
      other.holdExpiresAt == holdExpiresAt &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        reservationId,
        hotelId,
        status,
        amount,
        holdExpiresAt,
        createdAt,
        updatedAt,
      );

  @override
  String toString() => 'Payment($id, ${status.wireValue})';
}
