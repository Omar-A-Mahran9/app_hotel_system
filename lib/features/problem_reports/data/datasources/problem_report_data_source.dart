import '../../domain/entities/problem_report.dart';
import '../../domain/entities/submit_problem_report.dart';

/// The problem-reports data contract. Dummy + API implementations selected by
/// DI (`AppConfig.useDummyData`), exactly like the other features.
abstract interface class ProblemReportDataSource {
  Future<List<ProblemReport>> fetchList(String reservationId);

  Future<ProblemReport> fetchById(String reservationId, String reportId);

  Future<ProblemReport> submit(SubmitProblemReportRequest request);
}
