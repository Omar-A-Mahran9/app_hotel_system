import '../../data/data_source.dart';
import '../../errors/app_exception.dart';
import '../../network/api_client.dart';
import '../domain/backend_health.dart';
import 'health_data_source.dart';

/// API-backed health source.
///
/// Phase 0 foundation only: no `/health` endpoint is part of the approved
/// contract yet, so [fetchStatus] deliberately raises
/// [NotImplementedInPhaseException] rather than guessing a URL. The
/// [ApiClient] dependency and the wiring are in place; the single method body is
/// completed when the endpoint is approved (mobile/docs/README.md — "Backend-First
/// Rule").
class ApiHealthDataSource implements HealthDataSource, RemoteDataSource {
  ApiHealthDataSource(this._client);

  // Retained so wiring the approved endpoint stays a one-line change.
  // ignore: unused_field
  final ApiClient _client;

  @override
  Future<HealthStatus> fetchStatus() async {
    throw const NotImplementedInPhaseException(
      'Backend health endpoint is not part of the approved Phase 0 contract',
    );
  }
}
