import '../../../../core/data/data_source.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/payment_request.dart';
import '../models/payment_models.dart';
import 'payment_data_source.dart';

/// API-backed payment source.
///
/// Real, authenticated guest contract:
/// `GET /guest/reservations/{reservation}/payment` → `GuestPaymentResource`
/// or `{data: null}` when no payment exists yet, and
/// `POST /guest/reservations/{reservation}/payment/hold`.
///
/// The guest supplies no amount — the backend derives the deposit from
/// `config('guest_booking.deposit')` (a percentage of the reservation's price
/// snapshot; see `GuestPaymentController::resolveDepositAmount`). If that
/// config were ever unset, the endpoint refuses every call with a 422
/// (`api.guest_booking.deposit_rule_undefined`, `errors.reason ==
/// 'deposit_amount_rule_undefined'`) — the call propagates as a normal
/// [ValidationException] `Failure`; a bespoke "deposit unavailable" outcome
/// would need `PaymentDataSource.requestHold` to return a result wrapper
/// (like `RedeemPointsResult`), which ripples into the payment
/// repository/notifier/UI and is out of scope here.
class ApiPaymentDataSource implements PaymentDataSource, RemoteDataSource {
  ApiPaymentDataSource(this._client);

  final ApiClient _client;

  @override
  Future<PaymentModel?> fetchForReservation(String reservationId) async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/reservations/$reservationId/payment',
    );
    final Object? data = json['data'];
    if (data is! Map<String, Object?>) return null;
    return PaymentModel.fromJson(data);
  }

  @override
  Future<PaymentModel> requestHold(PaymentHoldRequest request) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/guest/reservations/${request.reservationId}/payment/hold',
      headers: <String, String>{'Idempotency-Key': request.idempotencyKey},
    );
    final Map<String, Object?>? meta = json['meta'] as Map<String, Object?>?;
    if (json['data'] == null && meta?['deposit_required'] == false) {
      return PaymentModel.notRequired(request.reservationId);
    }
    final Map<String, Object?> data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
    return PaymentModel.fromJson(data);
  }
}
