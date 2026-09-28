/// The loyalty ledger vocabulary, mirroring the Laravel
/// `App\Domain\Loyalty\Models\LoyaltyTransaction::TYPES` **exactly** (Phase 0
/// §13). No types are invented (mobile/docs/architecture.md §6).
///
/// The guest app only ever *creates* [earn] and [redeem] entries — the MVP
/// backend exposes no endpoint for the rest. [reverse] / [adjust] are
/// staff-only corrections; [expire] is reserved in the enum but **never
/// written** (R51: no expiration in the MVP). All five are modelled so the
/// history list can render whatever the backend returns.
enum LoyaltyTransactionType {
  earn('earn'),
  redeem('redeem'),
  reverse('reverse'),
  adjust('adjust'),
  expire('expire');

  const LoyaltyTransactionType(this.wireValue);

  /// The exact string the Laravel API uses (`snake_case`).
  final String wireValue;

  /// Parses an API value. An unknown value is a backend/mobile version skew — it
  /// maps to [adjust] defensively (a neutral "movement") rather than throwing.
  static LoyaltyTransactionType fromWire(String value) {
    for (final LoyaltyTransactionType t in LoyaltyTransactionType.values) {
      if (t.wireValue == value) return t;
    }
    return LoyaltyTransactionType.adjust;
  }

  /// The two operations the guest app can trigger in the MVP.
  bool get isGuestOperation =>
      this == LoyaltyTransactionType.earn || this == LoyaltyTransactionType.redeem;

  /// Whether this entry adds points to the balance (a positive delta). `redeem`
  /// and `expire` remove; `earn` adds; `reverse` / `adjust` are signed by the
  /// backend and read from [LoyaltyTransaction.points].
  bool get isCredit => this == LoyaltyTransactionType.earn;
}
