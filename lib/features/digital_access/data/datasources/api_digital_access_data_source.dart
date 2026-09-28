import 'package:dio/dio.dart';

import '../../../../core/data/data_source.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/check_in.dart';
import '../models/digital_access_models.dart';
import 'digital_access_data_source.dart';

/// API-backed digital-access source.
///
/// Real, authenticated guest contract:
/// `POST /guest/reservations/{reservation}/check-in` and
/// `GET /guest/reservations/{reservation}/access`, both → `AccessGrantResource`
/// (reused as-is; no guest-specific resource exists — see
/// `GuestCheckInController` / `GuestDigitalAccessController`). The service
/// independently re-verifies eligibility (VERIFIED + payment HOLD_ACTIVE +
/// identity approved + time eligibility) — this data source cannot and does
/// not skip any of it. There is no guest self-service revoke.
///
/// `GuestCheckInController::store` returns the full grant resource on success
/// (201/200) but only a bare `{status}` on the issuance-failed branch (422) —
/// the domain's `CheckInOutcome.issueFailed` is meant to come from a normally
/// parsed grant with `status == failed`, not an exception. On that 422 this
/// re-reads the authoritative grant via `GET .../access` (a real endpoint,
/// not a fabricated one) so the repository derives the outcome exactly as it
/// would from any other terminal grant state.
class ApiDigitalAccessDataSource
    implements DigitalAccessDataSource, RemoteDataSource {
  ApiDigitalAccessDataSource(this._client);

  final ApiClient _client;

  @override
  Future<AccessGrantModel?> fetchGrant(String reservationId) async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/reservations/$reservationId/access',
    );
    final Object? data = json['data'];
    if (data is! Map<String, Object?>) return null;
    return AccessGrantModel.fromJson(data);
  }

  @override
  Future<AccessGrantModel> checkIn(CheckInRequest request) async {
    try {
      final Map<String, dynamic> json = await _client.postJson(
        '/guest/reservations/${request.reservationId}/check-in',
        headers: <String, String>{'Idempotency-Key': request.idempotencyKey},
      );
      final Map<String, Object?> data =
          (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
      return AccessGrantModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final AccessGrantModel? grant = await fetchGrant(request.reservationId);
        if (grant != null) return grant;
      }
      rethrow;
    }
  }
}
