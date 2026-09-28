/// Reachability of the Laravel API, used by the startup/diagnostics foundation.
enum HealthStatus { ok, degraded, down }

/// Domain entity describing the result of a backend health probe.
class BackendHealth {
  const BackendHealth({required this.status, required this.checkedAt});

  final HealthStatus status;
  final DateTime checkedAt;

  @override
  bool operator ==(Object other) =>
      other is BackendHealth &&
      other.status == status &&
      other.checkedAt == checkedAt;

  @override
  int get hashCode => Object.hash(status, checkedAt);
}
