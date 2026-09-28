/// The digital-access grant lifecycle, mirroring the Laravel `AccessGrant`
/// status vocabulary **exactly** (backend
/// `App\Domain\DigitalAccess\Models\AccessGrant` constants and
/// `DigitalAccessStateMachine`; Phase 0 §11). The mobile state reflects the
/// backend state machine — no alternative states are invented
/// (mobile/docs/architecture.md §6).
enum AccessStatus {
  notIssued('not_issued'),
  issueRequested('issue_requested'),
  active('active'),
  failed('failed'),
  revokeRequested('revoke_requested'),
  revoked('revoked'),
  expired('expired');

  const AccessStatus(this.wireValue);

  /// The exact string the Laravel API uses (`snake_case`).
  final String wireValue;

  /// Parses an API value. An unknown value is a backend/mobile version skew — it
  /// maps to [notIssued] defensively rather than throwing.
  static AccessStatus fromWire(String value) {
    for (final AccessStatus s in AccessStatus.values) {
      if (s.wireValue == value) return s;
    }
    return AccessStatus.notIssued;
  }

  /// The credential is live and the door can be opened.
  bool get isActive => this == AccessStatus.active;

  /// Terminal in `DigitalAccessStateMachine` (`REVOKED`, `EXPIRED`).
  bool get isTerminal =>
      this == AccessStatus.revoked || this == AccessStatus.expired;

  /// A provider issuance attempt is in flight server-side.
  bool get isIssuing => this == AccessStatus.issueRequested;

  /// The last issuance attempt did not succeed — check-in can be retried
  /// (`FAILED → ISSUE_REQUESTED` is an approved edge).
  bool get isFailed => this == AccessStatus.failed;

  /// No credential exists yet — check-in has not run.
  bool get isNotIssued => this == AccessStatus.notIssued;
}

/// How the guest opens the door, mirroring `AccessGrant::MODES`. The MVP
/// provider is `pin_code` (an app-delivered code); `smart_lock` is modelled for
/// completeness so the credential view can branch without inventing a mode.
enum AccessMode {
  pinCode('pin_code'),
  smartLock('smart_lock');

  const AccessMode(this.wireValue);

  final String wireValue;

  static AccessMode fromWire(String? value) {
    for (final AccessMode m in AccessMode.values) {
      if (m.wireValue == value) return m;
    }
    return AccessMode.pinCode;
  }
}
