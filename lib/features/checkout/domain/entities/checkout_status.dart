/// The checkout process lifecycle, mirroring the Laravel `Checkout` status
/// vocabulary **exactly** (backend `App\Domain\Checkout\Models\Checkout`
/// constants and `CheckoutStateMachine`; Phase 0 §12). No new statuses are
/// invented (mobile/docs/architecture.md §6).
///
/// ```
/// in_progress ─┐
/// awaiting_settlement ─┼─► completed (terminal)
/// settlement_failed ───┘   (the non-completed three form a retry cluster)
/// ```
enum CheckoutStatus {
  inProgress('in_progress'),
  awaitingSettlement('awaiting_settlement'),
  settlementFailed('settlement_failed'),
  completed('completed');

  const CheckoutStatus(this.wireValue);

  final String wireValue;

  static CheckoutStatus fromWire(String value) {
    for (final CheckoutStatus s in CheckoutStatus.values) {
      if (s.wireValue == value) return s;
    }
    return CheckoutStatus.inProgress;
  }

  /// The reservation is invoiced and the invoice issued — terminal.
  bool get isComplete => this == CheckoutStatus.completed;

  /// A required final settlement is still resolving server-side.
  bool get isSettlementPending => this == CheckoutStatus.awaitingSettlement;

  /// A required final settlement did not succeed — retryable.
  bool get isSettlementFailed => this == CheckoutStatus.settlementFailed;
}

/// The invoice document state, mirroring `Invoice::STATUSES` (`draft`,
/// `issued`).
enum InvoiceStatus {
  draft('draft'),
  issued('issued');

  const InvoiceStatus(this.wireValue);

  final String wireValue;

  static InvoiceStatus fromWire(String? value) =>
      value == 'issued' ? InvoiceStatus.issued : InvoiceStatus.draft;

  bool get isIssued => this == InvoiceStatus.issued;
}
