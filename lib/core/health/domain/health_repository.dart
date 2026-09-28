import '../../errors/failure.dart';
import 'backend_health.dart';

/// Contract the UI/state layer depends on. Implementations may be dummy- or
/// API-backed without the caller knowing (mobile/docs/architecture.md §4).
///
/// Throws a [Failure] on error so callers only ever handle the user-safe type.
abstract interface class HealthRepository {
  Future<BackendHealth> check();
}
