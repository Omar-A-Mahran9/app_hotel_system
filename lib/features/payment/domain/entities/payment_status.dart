/// The payment money-lifecycle, mirroring the Laravel `Payment` status
/// vocabulary **exactly** (backend `App\Domain\Payment\Models\Payment`
/// constants and `PaymentStateMachine`; mobile/docs/architecture.md §6 — "Laravel
/// MUST remain authoritative for … payment state").
///
/// Mobile Phase 5 only ever *requests a hold* (`POST
/// /reservations/{id}/payment/hold`), so the app itself only drives
/// `NOT_STARTED → HOLD_REQUESTED → HOLD_ACTIVE`. The rest of the lifecycle
/// (capture, settlement, refund) is staff/back-office and webhook driven; the
/// full set is modelled here so the payment screens can render whatever status
/// the backend reports and never collapse it to a boolean "paid".
enum PaymentStatus {
  notStarted('not_started'),
  holdRequested('hold_requested'),
  holdActive('hold_active'),
  holdFailed('hold_failed'),
  captureRequested('capture_requested'),
  captured('captured'),
  captureFailed('capture_failed'),
  finalSettlementRequested('final_settlement_requested'),
  settled('settled'),
  settlementFailed('settlement_failed'),
  cancelled('cancelled'),
  expired('expired'),
  refundRequested('refund_requested'),
  refunded('refunded'),
  refundFailed('refund_failed');

  const PaymentStatus(this.wireValue);

  /// The exact string the Laravel API uses (`snake_case`).
  final String wireValue;

  /// Parses an API value. An unknown value is a backend/mobile version skew — it
  /// maps to [notStarted] defensively rather than throwing; a caller building on
  /// an authoritative response should treat that as a logged anomaly.
  static PaymentStatus fromWire(String value) {
    for (final PaymentStatus status in PaymentStatus.values) {
      if (status.wireValue == value) return status;
    }
    return PaymentStatus.notStarted;
  }

  /// Terminal statuses have no outgoing transition in `PaymentStateMachine`
  /// (`SETTLED`, `CANCELLED`, `EXPIRED`, `REFUNDED`, `REFUND_FAILED`).
  bool get isTerminal => switch (this) {
        PaymentStatus.settled ||
        PaymentStatus.cancelled ||
        PaymentStatus.expired ||
        PaymentStatus.refunded ||
        PaymentStatus.refundFailed =>
          true,
        _ => false,
      };

  /// The guest has money secured for the reservation — an active authorization
  /// hold, a capture or a completed settlement. An explicit positive list,
  /// never a negation (mirrors `Payment::CAPTURED_STATUSES` plus the hold).
  bool get isSecured => switch (this) {
        PaymentStatus.holdActive ||
        PaymentStatus.captured ||
        PaymentStatus.finalSettlementRequested ||
        PaymentStatus.settled =>
          true,
        _ => false,
      };

  /// Nothing is in flight and no hold exists yet — the "Pay now" action is
  /// offered from here (and from [holdFailed], where the state machine allows a
  /// fresh `HOLD_REQUESTED`).
  bool get canRequestHold =>
      this == PaymentStatus.notStarted || this == PaymentStatus.holdFailed;

  /// A hold request the backend has accepted but not yet resolved.
  bool get isPending => this == PaymentStatus.holdRequested;

  /// The most recent hold attempt did not succeed — a safe, retryable outcome.
  bool get isFailed => switch (this) {
        PaymentStatus.holdFailed ||
        PaymentStatus.captureFailed ||
        PaymentStatus.settlementFailed ||
        PaymentStatus.refundFailed =>
          true,
        _ => false,
      };
}
