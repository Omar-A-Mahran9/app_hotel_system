/// The identity-verification session lifecycle, mirroring the Laravel
/// `IdentityVerificationSession` status vocabulary **exactly** (backend
/// `App\Domain\IdentityVerification\Models\IdentityVerificationSession`
/// constants and `IdentityVerificationStateMachine`; Phase 0 §10). The mobile
/// state must reflect the backend state machine — no alternative states are
/// invented (mobile/docs/feature_guide.md).
enum IdentityVerificationStatus {
  notStarted('not_started'),
  documentUploaded('document_uploaded'),
  selfieCaptured('selfie_captured'),
  matchingInProgress('matching_in_progress'),
  autoApproved('auto_approved'),
  pendingManualReview('pending_manual_review'),
  staffApproved('staff_approved'),
  staffRejected('staff_rejected'),
  retryAllowed('retry_allowed');

  const IdentityVerificationStatus(this.wireValue);

  /// The exact string the Laravel API uses (`snake_case`).
  final String wireValue;

  /// Parses an API value. An unknown value is a backend/mobile version skew — it
  /// maps to [notStarted] defensively rather than throwing; a caller building on
  /// an authoritative response should treat that as a logged anomaly.
  static IdentityVerificationStatus fromWire(String value) {
    for (final IdentityVerificationStatus s
        in IdentityVerificationStatus.values) {
      if (s.wireValue == value) return s;
    }
    return IdentityVerificationStatus.notStarted;
  }

  /// The guest's identity is confirmed for the reservation workflow — an
  /// explicit positive list, never a negation (mirrors
  /// `IdentityVerificationSession::APPROVED_STATUSES`).
  bool get isApproved =>
      this == IdentityVerificationStatus.autoApproved ||
      this == IdentityVerificationStatus.staffApproved;

  /// Terminal in `IdentityVerificationStateMachine` (`AUTO_APPROVED`,
  /// `STAFF_APPROVED`). `STAFF_REJECTED` is deliberately **not** terminal — the
  /// state machine gives it a retry edge back to `DOCUMENT_UPLOADED`.
  bool get isTerminal => isApproved;

  /// A staff member is (or will be) reviewing the submission manually.
  bool get isManualReview => this == IdentityVerificationStatus.pendingManualReview;

  /// The automated match is running server-side.
  bool get isProcessing => switch (this) {
        IdentityVerificationStatus.selfieCaptured ||
        IdentityVerificationStatus.matchingInProgress =>
          true,
        _ => false,
      };

  /// The guest still needs to (re)submit an ID document.
  bool get needsDocument => switch (this) {
        IdentityVerificationStatus.notStarted ||
        IdentityVerificationStatus.retryAllowed ||
        IdentityVerificationStatus.staffRejected =>
          true,
        _ => false,
      };

  /// A document is on file and a selfie is the next step.
  bool get needsSelfie => this == IdentityVerificationStatus.documentUploaded;

  /// The state machine allows another attempt from here (`RETRY_ALLOWED` and
  /// `STAFF_REJECTED` both have an edge back to `DOCUMENT_UPLOADED`). Whether a
  /// retry is *actually* permitted (retry-count limit) stays a backend
  /// decision — the app only offers the action.
  bool get allowsRetry => switch (this) {
        IdentityVerificationStatus.retryAllowed ||
        IdentityVerificationStatus.staffRejected =>
          true,
        _ => false,
      };
}
