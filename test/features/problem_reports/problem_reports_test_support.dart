import 'package:hotel_guest_app/features/problem_reports/data/datasources/dummy_problem_report_data_source.dart';

/// The first reservation id whose deterministic dummy history matches
/// [scenario] — mirrors `reservationIdWithCancellableOrder` in
/// `stay_services_test_support.dart`.
String reservationIdForProblemScenario(DummyProblemReportScenario scenario) {
  for (int i = 0; i < 800; i++) {
    final String rid = 'pr$i';
    if (DummyProblemReportDataSource.scenarioFor(rid) == scenario) return rid;
  }
  throw StateError('no reservation id found for $scenario');
}
