import '../domain/backend_health.dart';

/// Data-source contract for the backend health probe. Concrete implementations
/// are [DummyHealthDataSource] and [ApiHealthDataSource].
///
/// Returns a [HealthStatus]; raising an [AppException] signals an unreachable or
/// failing backend.
abstract interface class HealthDataSource {
  Future<HealthStatus> fetchStatus();
}
