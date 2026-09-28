import '../../data/data_source.dart';
import '../domain/backend_health.dart';
import 'health_data_source.dart';

/// In-memory health source used while no approved `/health` endpoint is wired.
///
/// Defaults to [HealthStatus.ok]. Tests override [nextStatus] / [error] to
/// exercise the degraded, down and failure paths without any HTTP or UI.
class DummyHealthDataSource implements HealthDataSource, DummyDataSource {
  DummyHealthDataSource({this.nextStatus = HealthStatus.ok, this.error});

  HealthStatus nextStatus;
  Object? error;

  @override
  Future<HealthStatus> fetchStatus() async {
    if (error != null) throw error!;
    return nextStatus;
  }
}
