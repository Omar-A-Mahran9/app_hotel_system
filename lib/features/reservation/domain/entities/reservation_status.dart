/// The reservation lifecycle, mirroring the Laravel `Reservation` status enum
/// **exactly** (backend `App\Domain\Reservation\Models\Reservation` constants;
/// mobile/docs/feature_guide.md — "Hotel-Specific Rule: the mobile state must
/// reflect the Laravel state machine. Do not invent alternative states").
///
/// Mobile Phase 4 only ever *creates* a reservation, which the backend places in
/// [pending]. The later phases (payment, identity, check-in, checkout) drive the
/// transitions; the full set is modelled here so those phases have one home for
/// the mapping and the success screen can render any status the backend returns.
enum ReservationStatus {
  pending('pending'),
  depositHeld('deposit_held'),
  verified('verified'),
  checkedIn('checked_in'),
  inStay('in_stay'),
  checkoutInProgress('checkout_in_progress'),
  checkoutBlocked('checkout_blocked'),
  checkedOut('checked_out'),
  invoiced('invoiced'),
  cancelled('cancelled');

  const ReservationStatus(this.wireValue);

  /// The exact string the Laravel API uses (`snake_case`).
  final String wireValue;

  /// Parses an API value. An unknown value is a backend/mobile version skew — it
  /// maps to [pending] defensively rather than throwing, but callers building on
  /// an authoritative response should treat that as a logged anomaly.
  static ReservationStatus fromWire(String value) {
    for (final ReservationStatus status in ReservationStatus.values) {
      if (status.wireValue == value) return status;
    }
    return ReservationStatus.pending;
  }

  /// A freshly created reservation is not yet secured — the deposit hold
  /// (Phase 5) is the next step in the approved state machine.
  bool get isAwaitingPayment => this == ReservationStatus.pending;

  bool get isCancelled => this == ReservationStatus.cancelled;
}
