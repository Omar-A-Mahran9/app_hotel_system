import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/time/clock.dart';
import '../../data/datasources/api_problem_report_data_source.dart';
import '../../data/datasources/dummy_problem_report_data_source.dart';
import '../../data/datasources/problem_report_data_source.dart';
import '../../data/repositories/problem_report_repository_impl.dart';
import '../../domain/entities/problem_report.dart';
import '../../domain/repositories/problem_report_repository.dart';

/// One dummy instance holds any reports created this session so a later fetch
/// is consistent. Kept alive.
final _dummyProblemReportProvider = Provider<DummyProblemReportDataSource>(
  (Ref ref) => DummyProblemReportDataSource(clock: ref.watch(clockProvider)),
);

/// Selects the problem-reports data source by configuration — mirrors
/// `reviewDataSourceProvider`.
final problemReportDataSourceProvider = Provider<ProblemReportDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? ref.watch(_dummyProblemReportProvider)
      : ApiProblemReportDataSource(ref.watch(apiClientProvider));
});

final problemReportRepositoryProvider = Provider<ProblemReportRepository>(
  (Ref ref) => ProblemReportRepositoryImpl(ref.watch(problemReportDataSourceProvider)),
);

/// The guest's own reports for a reservation, newest first.
final problemReportsProvider = FutureProvider.autoDispose
    .family<List<ProblemReport>, String>((Ref ref, String reservationId) {
  return ref.watch(problemReportRepositoryProvider).listFor(reservationId);
});

/// A single problem report — the "track report" screen.
typedef ProblemReportKey = ({String reservationId, String reportId});

final problemReportProvider = FutureProvider.autoDispose
    .family<ProblemReport, ProblemReportKey>((Ref ref, ProblemReportKey key) {
  return ref
      .watch(problemReportRepositoryProvider)
      .reportById(key.reservationId, key.reportId);
});
