import 'package:flutter/foundation.dart';

import 'loyalty_transaction_type.dart';

/// One append-only entry in the loyalty ledger, mirroring the safe fields of
/// the Laravel `LoyaltyTransactionResource` (`id`, `type`, `points` — a signed
/// delta, `source_type`, `source_id`, `description`, `metadata`, `created_at`).
///
/// `metadata` on the backend carries a couple of non-sensitive figures
/// (`earn_base_amount`, `notional_value`); no card / payment / provider data is
/// ever on a loyalty entry.
@immutable
class LoyaltyTransaction {
  const LoyaltyTransaction({
    required this.id,
    required this.type,
    required this.points,
    this.description,
    this.sourceType,
    this.sourceId,
    this.createdAt,
    this.earnBaseAmount,
    this.notionalValue,
  });

  final String id;
  final LoyaltyTransactionType type;

  /// Signed delta: positive for [LoyaltyTransactionType.earn], negative for
  /// [LoyaltyTransactionType.redeem] / expire. Read verbatim from the ledger.
  final int points;

  final String? description;

  /// `reservation` for guest operations (backend
  /// `LoyaltyTransaction::SOURCE_RESERVATION`).
  final String? sourceType;
  final String? sourceId;
  final DateTime? createdAt;

  /// From `metadata.earn_base_amount` — the booking value the earn was based
  /// on, as a decimal string. Display-only.
  final String? earnBaseAmount;

  /// From `metadata.notional_value` — the notional monetary value of a
  /// redemption, as a decimal string. The actual discount mechanism is a
  /// deferred backend integration; this is display-only.
  final String? notionalValue;

  /// The unsigned magnitude, for display alongside a +/- sign.
  int get magnitude => points.abs();

  bool get isCredit => points > 0;
  bool get isDebit => points < 0;

  /// Whether this entry was created against [reservationId].
  bool isForReservation(String reservationId) =>
      sourceType == 'reservation' && sourceId == reservationId;

  @override
  bool operator ==(Object other) =>
      other is LoyaltyTransaction &&
      other.id == id &&
      other.type == type &&
      other.points == points &&
      other.description == description &&
      other.sourceType == sourceType &&
      other.sourceId == sourceId &&
      other.createdAt == createdAt &&
      other.earnBaseAmount == earnBaseAmount &&
      other.notionalValue == notionalValue;

  @override
  int get hashCode => Object.hashAll(<Object?>[
        id,
        type,
        points,
        description,
        sourceType,
        sourceId,
        createdAt,
        earnBaseAmount,
        notionalValue,
      ]);

  @override
  String toString() =>
      'LoyaltyTransaction($id, ${type.wireValue}, $points)';
}
