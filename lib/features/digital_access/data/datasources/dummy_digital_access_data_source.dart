import '../../../../core/data/data_source.dart';
import '../../domain/entities/access_status.dart';
import '../../domain/entities/check_in.dart';
import '../models/digital_access_models.dart';
import 'digital_access_data_source.dart';

/// A deterministic check-in scenario, chosen purely from the reservation id.
enum DummyCheckInScenario {
  /// Eligible — the grant goes `ACTIVE` on the first check-in.
  issuesActive,

  /// Issuance `FAILED` first; a retry succeeds (`ACTIVE`).
  failsThenActive,

  /// The provider call stays pending (`ISSUE_REQUESTED`).
  staysPending,
}

/// Deterministic, offline digital-access source used while no guest-facing
/// check-in / access contract is approved.
///
/// Guarantees required by the phase brief:
/// * no network, no timers, no randomness, no `DateTime.now()` branching (a
///   `clock` is injected for display timestamps only);
/// * the resolved status is a pure function of the reservation id (via
///   [scenarioFor]) and the attempt count;
/// * `checkIn` is idempotent for a non-failed grant: a repeat returns the
///   stored grant. A `FAILED` grant is not cached, so a genuine retry
///   re-attempts and (per [scenarioFor]) then succeeds;
/// * a reservation with no check-in yet reports no grant;
/// * the credential is a deterministic 6-digit code and is only ever attached
///   to an `ACTIVE` grant.
///
/// [failWith] is a test seam (mirrors `DummyPaymentDataSource.failWith`).
/// [seedGrant] lets tests place a reservation into a specific terminal state
/// (`revoked` / `expired`) without any real transition.
class DummyDigitalAccessDataSource
    implements DigitalAccessDataSource, DummyDataSource {
  DummyDigitalAccessDataSource({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    // The dummy reservation source's checked-in stay (`seed-in-stay`, room
    // 412) already holds its active key — as the backend always has one for a
    // checked-in stay.
    _byReservation[_checkedInSeedId] = _model(
      _checkedInSeedId,
      AccessStatus.active,
      attempts: 1,
      roomNumber: '412',
    );
  }

  static const String _checkedInSeedId = 'seed-in-stay';

  final DateTime Function() _clock;
  final Map<String, AccessGrantModel> _byKey = <String, AccessGrantModel>{};
  final Map<String, AccessGrantModel> _byReservation =
      <String, AccessGrantModel>{};
  final Map<String, int> _attempts = <String, int>{};

  /// When non-null, the next call throws this instead.
  Object? failWith;

  static DummyCheckInScenario scenarioFor(String reservationId) {
    switch (_fnv1a(reservationId) % 3) {
      case 0:
        return DummyCheckInScenario.issuesActive;
      case 1:
        return DummyCheckInScenario.failsThenActive;
      default:
        return DummyCheckInScenario.staysPending;
    }
  }

  /// Test-only: place [reservationId] into a specific status directly.
  void seedGrant(String reservationId, AccessStatus status) {
    _byReservation[reservationId] = _model(reservationId, status, attempts: 1);
  }

  @override
  Future<AccessGrantModel?> fetchGrant(String reservationId) async {
    if (failWith != null) throw failWith!;
    return _byReservation[reservationId];
  }

  @override
  Future<AccessGrantModel> checkIn(CheckInRequest request) async {
    if (failWith != null) throw failWith!;

    final AccessGrantModel? cached = _byKey[request.idempotencyKey];
    if (cached != null && cached.status != AccessStatus.failed) return cached;

    // Already checked in from a prior call — replay it.
    final AccessGrantModel? existing = _byReservation[request.reservationId];
    if (existing != null && existing.status == AccessStatus.active) {
      return existing;
    }

    final int attempts = (_attempts[request.reservationId] ?? 0) + 1;
    _attempts[request.reservationId] = attempts;

    final AccessStatus status = _resolve(request.reservationId, attempts);
    final AccessGrantModel model =
        _model(request.reservationId, status, attempts: attempts);

    if (status != AccessStatus.failed) _byKey[request.idempotencyKey] = model;
    _byReservation[request.reservationId] = model;
    return model;
  }

  AccessStatus _resolve(String reservationId, int attempts) {
    return switch (scenarioFor(reservationId)) {
      DummyCheckInScenario.issuesActive => AccessStatus.active,
      DummyCheckInScenario.failsThenActive =>
        attempts <= 1 ? AccessStatus.failed : AccessStatus.active,
      DummyCheckInScenario.staysPending => AccessStatus.issueRequested,
    };
  }

  AccessGrantModel _model(
    String reservationId,
    AccessStatus status, {
    required int attempts,
    String? roomNumber,
  }) {
    final DateTime now = _clock();
    final int hash = _fnv1a(reservationId);
    final bool active = status == AccessStatus.active;
    return AccessGrantModel.fromJson(<String, Object?>{
      'reservation_id': reservationId,
      'status': status.wireValue,
      'access_mode': AccessMode.pinCode.wireValue,
      'provider': 'dummy',
      'room_number': roomNumber ?? '${100 + (hash % 400)}',
      'credential': active
          ? (100000 + (hash % 900000)).toString()
          : null,
      'issued_at': status == AccessStatus.notIssued
          ? null
          : now.toIso8601String(),
      'activated_at': active ? now.toIso8601String() : null,
      'expires_at':
          active ? now.add(const Duration(days: 2)).toIso8601String() : null,
      'revoked_at': status == AccessStatus.revoked
          ? now.toIso8601String()
          : null,
      'revocation_reason':
          status == AccessStatus.revoked ? 'stay_ended' : null,
      'failure_reason':
          status == AccessStatus.failed ? 'provider_unavailable' : null,
    });
  }

  static int _fnv1a(String value) {
    int hash = 0x811c9dc5;
    for (final int unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
