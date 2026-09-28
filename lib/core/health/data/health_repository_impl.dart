import '../../errors/error_mapper.dart';
import '../domain/backend_health.dart';
import '../domain/health_repository.dart';
import 'health_data_source.dart';

/// Coordinates the health data source and maps failures to the domain contract.
///
/// Which [HealthDataSource] it receives (dummy vs API) is decided by DI, not
/// here (mobile/docs/feature_guide.md Step 5).
class HealthRepositoryImpl implements HealthRepository {
  HealthRepositoryImpl(this._dataSource);

  final HealthDataSource _dataSource;

  @override
  Future<BackendHealth> check() async {
    try {
      final HealthStatus status = await _dataSource.fetchStatus();
      return BackendHealth(status: status, checkedAt: DateTime.now());
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }
}
