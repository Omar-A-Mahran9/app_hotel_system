import '../../../../core/data/data_source.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/entities/payment_status.dart';
import '../models/payment_models.dart';
import 'payment_data_source.dart';

/// A deterministic hold-request scenario, chosen purely from the reservation id
/// so the same reservation always behaves the same way. No randomness, no
/// time-derived branching.
enum DummyHoldScenario {
  /// The first attempt fails (`HOLD_FAILED`); a retry succeeds (`HOLD_ACTIVE`).
  failsThenSucceeds,

  /// The hold is accepted but stays `HOLD_REQUESTED` (e.g. awaiting a webhook).
  staysPending,

  /// The hold goes active immediately (`HOLD_ACTIVE`).
  succeeds,
}

/// Deterministic, offline payment source used while no guest-facing payment API
/// contract is approved.
///
/// Guarantees required by the phase brief:
/// * no network, no timers, no randomness, no artificial delays;
/// * the resolved status is a pure function of the reservation id (via
///   [scenarioFor]) and the attempt count — the same reservation always
///   behaves the same;
/// * [requestHold] is idempotent for a *successful/pending* result: repeating
///   the same request returns the stored payment, it never runs a second
///   operation. A `HOLD_FAILED` result is deliberately not cached, so a genuine
///   retry with the same key re-attempts (and, per [scenarioFor], then
///   succeeds);
/// * a reservation with no hold yet reports no payment.
///
/// [failWith] is a test seam (mirrors `DummyReservationDataSource.failWith`) so
/// the infrastructure-error / recovery UI can be exercised.
class DummyPaymentDataSource implements PaymentDataSource, DummyDataSource {
  DummyPaymentDataSource({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, PaymentModel> _byKey = <String, PaymentModel>{};
  final Map<String, PaymentModel> _latestByReservation = <String, PaymentModel>{};
  final Map<String, int> _attemptsByReservation = <String, int>{};

  /// When non-null, the next call throws this instead.
  Object? failWith;

  /// The deterministic scenario for a reservation id.
  static DummyHoldScenario scenarioFor(String reservationId) {
    switch (_fnv1a(reservationId) % 3) {
      case 0:
        return DummyHoldScenario.failsThenSucceeds;
      case 1:
        return DummyHoldScenario.staysPending;
      default:
        return DummyHoldScenario.succeeds;
    }
  }

  @override
  Future<PaymentModel?> fetchForReservation(String reservationId) async {
    if (failWith != null) throw failWith!;
    return _latestByReservation[reservationId];
  }

  @override
  Future<PaymentModel> requestHold(PaymentHoldRequest request) async {
    if (failWith != null) throw failWith!;

    final PaymentModel? cached = _byKey[request.idempotencyKey];
    if (cached != null && !cached.status.isFailed) return cached;

    final int attempts =
        (_attemptsByReservation[request.reservationId] ?? 0) + 1;
    _attemptsByReservation[request.reservationId] = attempts;

    final PaymentStatus status = _resolve(request.reservationId, attempts);
    final PaymentModel model = _model(request, status);

    if (!status.isFailed) _byKey[request.idempotencyKey] = model;
    _latestByReservation[request.reservationId] = model;
    return model;
  }

  PaymentStatus _resolve(String reservationId, int attempts) {
    return switch (scenarioFor(reservationId)) {
      DummyHoldScenario.failsThenSucceeds =>
        attempts <= 1 ? PaymentStatus.holdFailed : PaymentStatus.holdActive,
      DummyHoldScenario.staysPending => PaymentStatus.holdRequested,
      DummyHoldScenario.succeeds => PaymentStatus.holdActive,
    };
  }

  PaymentModel _model(PaymentHoldRequest request, PaymentStatus status) {
    final DateTime now = _clock();
    final int hash = _fnv1a(request.idempotencyKey);
    return PaymentModel.fromJson(<String, Object?>{
      'id': status == PaymentStatus.holdFailed
          ? null
          : '${2000000 + (hash % 8000000)}',
      'reservation_id': request.reservationId,
      // The dummy has no hotel context; the UI reads the hotel from the
      // authoritative reservation, never from the payment record.
      'hotel_id': '',
      'status': status.wireValue,
      'amount': request.amount.amount.toStringAsFixed(2),
      'currency': request.amount.currency,
      'hold_expires_at': status == PaymentStatus.holdActive
          ? now.add(const Duration(days: 1)).toIso8601String()
          : null,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
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
