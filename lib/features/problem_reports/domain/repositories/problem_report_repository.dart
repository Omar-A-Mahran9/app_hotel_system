import '../entities/problem_report.dart';
import '../entities/submit_problem_report.dart';

/// The problem-reports contract the presentation layer depends on
/// (mobile/docs/architecture.md §4). Dummy vs API is a DI decision, exactly
/// as in `ReviewRepository`.
///
/// Every method throws a `Failure` on error (mapped by the implementation).
/// Ownership/ordering/the initial `open` status are all resolved server-side.
abstract interface class ProblemReportRepository {
  /// The guest's own reports for a reservation, newest first.
  Future<List<ProblemReport>> listFor(String reservationId);

  /// A single report by id — for the "track report" screen.
  Future<ProblemReport> reportById(String reservationId, String reportId);

  /// Submits a new report. Always lands in `open`.
  Future<ProblemReport> submit(SubmitProblemReportRequest request);
}
