import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/problem_report.dart';
import '../../domain/entities/submit_problem_report.dart';
import '../../domain/repositories/problem_report_repository.dart';
import '../datasources/problem_report_data_source.dart';

/// Coordinates the problem-reports data source. Dummy vs API is a DI
/// decision. Every data-layer error is mapped to a `Failure` via
/// [ErrorMapper].
class ProblemReportRepositoryImpl implements ProblemReportRepository {
  ProblemReportRepositoryImpl(this._dataSource);

  final ProblemReportDataSource _dataSource;

  @override
  Future<List<ProblemReport>> listFor(String reservationId) =>
      _guard(() => _dataSource.fetchList(reservationId));

  @override
  Future<ProblemReport> reportById(String reservationId, String reportId) =>
      _guard(() => _dataSource.fetchById(reservationId, reportId));

  @override
  Future<ProblemReport> submit(SubmitProblemReportRequest request) =>
      _guard(() => _dataSource.submit(request));

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }
}
