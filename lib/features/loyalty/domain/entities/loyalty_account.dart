import 'package:flutter/foundation.dart';

/// The guest's group-wide loyalty account, mirroring the safe fields of the
/// Laravel `LoyaltyAccountResource` (`id`, `guest_id`, `points_balance`,
/// `is_active`, `created_at`, `updated_at`).
///
/// ACCOUNTING: [pointsBalance] is a **backend cache** — the transaction ledger
/// is authoritative. The app displays this value and never computes a new
/// balance client-side after an earn/redeem; it re-reads the account instead
/// (Phase 0 §13, guardrail #8).
///
/// [isActive] reflects whether the group's loyalty program is configured and
/// running. It is `false` until a Group Owner sets a valid rule — there is no
/// seeded / default earning rate, and loyalty is OFF until then.
@immutable
class LoyaltyAccount {
  const LoyaltyAccount({
    required this.pointsBalance,
    required this.isActive,
    this.id,
    this.guestId,
  });

  /// A synthetic "no account resolved" placeholder (0 points, inactive) — used
  /// only while an authoritative account is loading or unavailable.
  static const LoyaltyAccount unknown =
      LoyaltyAccount(pointsBalance: 0, isActive: false);

  /// The account primary key, when the resource exposes it.
  final String? id;

  /// The owning guest id, when the resource exposes it. The app never sends
  /// this back — the backend resolves guest identity server-side.
  final String? guestId;

  final int pointsBalance;
  final bool isActive;

  bool get hasPoints => pointsBalance > 0;

  @override
  bool operator ==(Object other) =>
      other is LoyaltyAccount &&
      other.id == id &&
      other.guestId == guestId &&
      other.pointsBalance == pointsBalance &&
      other.isActive == isActive;

  @override
  int get hashCode => Object.hash(id, guestId, pointsBalance, isActive);

  @override
  String toString() =>
      'LoyaltyAccount($pointsBalance pts, active: $isActive)';
}
