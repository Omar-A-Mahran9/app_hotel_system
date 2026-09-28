/// The problem-report lifecycle, mirroring
/// `App\Domain\Support\Models\ProblemReport::STATUSES` /
/// `ProblemReportService::ALLOWED_TRANSITIONS` exactly (Phase 11 addendum).
/// The guest never sets this — it is server-derived and starts at [open].
///
/// ```
/// open -> in_progress -> resolved
/// open -> resolved            (a quick close)
/// ```
/// No reopening, no reject — this is operational triage, not the Review
/// moderation flow.
enum ProblemReportStatus {
  open('open'),
  inProgress('in_progress'),
  resolved('resolved');

  const ProblemReportStatus(this.wireValue);

  final String wireValue;

  /// Falls back to [open] for anything unrecognised.
  static ProblemReportStatus fromWire(String? value) {
    for (final ProblemReportStatus s in ProblemReportStatus.values) {
      if (s.wireValue == value) return s;
    }
    return ProblemReportStatus.open;
  }

  bool get isOpen => this == ProblemReportStatus.open;
  bool get isInProgress => this == ProblemReportStatus.inProgress;
  bool get isResolved => this == ProblemReportStatus.resolved;
}
