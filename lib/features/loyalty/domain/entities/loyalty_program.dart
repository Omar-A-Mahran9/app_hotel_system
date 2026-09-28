import 'package:flutter/foundation.dart';

/// The hotel group's live loyalty program + the guest's balance, as the
/// booking summary shows it before a reservation exists
/// (`GET /guest/hotels/{hotel}/loyalty`). Every value comes from the backend —
/// at launch the program is off (`enabled: false`, all zero).
@immutable
class LoyaltyProgram {
  const LoyaltyProgram({
    required this.enabled,
    required this.redeemValuePerPoint,
    required this.maxRedeemPoints,
    required this.pointsBalance,
    required this.redeemablePoints,
  });

  static const LoyaltyProgram disabled = LoyaltyProgram(
    enabled: false,
    redeemValuePerPoint: 0,
    maxRedeemPoints: 0,
    pointsBalance: 0,
    redeemablePoints: 0,
  );

  final bool enabled;

  /// Currency value of one point (`redeem_currency_per_point`).
  final num redeemValuePerPoint;

  /// The per-booking redemption cap (`max_redeem_points`).
  final int maxRedeemPoints;

  final int pointsBalance;

  /// `min(balance, max)` when enabled — the most the guest may redeem here.
  final int redeemablePoints;

  /// Whether the guest can redeem anything on this booking.
  bool get canRedeem => enabled && redeemablePoints > 0 && redeemValuePerPoint > 0;

  /// The discount [points] are worth, capped at [stayTotal] — the same
  /// arithmetic the backend applies (`points × rate`, capped at the stay).
  /// Rounded to halalas; a display estimate only, the server decides.
  num discountFor(int points, {required num stayTotal}) {
    if (points <= 0) return 0;
    final int halalas = (points * redeemValuePerPoint * 100).floor();
    final int capHalalas = (stayTotal * 100).round();
    return (halalas > capHalalas ? capHalalas : halalas) / 100;
  }

  /// The points needed for a [discount] (inverse of [discountFor]), clamped
  /// to [redeemablePoints].
  int pointsFor(num discount) {
    if (redeemValuePerPoint <= 0 || discount <= 0) return 0;
    final int points = (discount / redeemValuePerPoint).ceil();
    return points > redeemablePoints ? redeemablePoints : points;
  }

  @override
  bool operator ==(Object other) =>
      other is LoyaltyProgram &&
      other.enabled == enabled &&
      other.redeemValuePerPoint == redeemValuePerPoint &&
      other.maxRedeemPoints == maxRedeemPoints &&
      other.pointsBalance == pointsBalance &&
      other.redeemablePoints == redeemablePoints;

  @override
  int get hashCode => Object.hash(
        enabled,
        redeemValuePerPoint,
        maxRedeemPoints,
        pointsBalance,
        redeemablePoints,
      );
}
