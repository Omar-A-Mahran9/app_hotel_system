import 'package:dio/dio.dart';

import '../../../../core/data/data_source.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/loyalty_account.dart';
import '../../domain/entities/loyalty_operations.dart';
import '../../domain/entities/loyalty_program.dart';
import '../../domain/entities/loyalty_transaction.dart';
import '../models/loyalty_models.dart';
import 'loyalty_data_source.dart';

/// API-backed loyalty source.
///
/// Real, authenticated guest contract, reused as-is (no guest-specific
/// resource needed):
/// `GET /guest/reservations/{reservation}/loyalty` → `LoyaltyAccountResource`
/// `GET  .../loyalty/transactions` → `LoyaltyTransactionResource[]`
/// `POST .../loyalty/redeem` (`{points}`) → `LoyaltyTransactionResource` (201)
///
/// There is **no guest `earn`**: points accrue automatically when the stay
/// completes (the backend's lifecycle accrual listener, idempotent). The
/// staff `earn` route is a manual escape hatch, not a guest action.
///
/// `redeem`'s business-precondition failures (`LoyaltyNotAllowedException`)
/// now carry a machine `errors.reason` (added to `bootstrap/app.php`'s
/// exception envelope alongside the existing `deposit_amount_rule_undefined`
/// pattern) so the real outcome can be classified instead of guessed from
/// localized text.
class ApiLoyaltyDataSource implements LoyaltyDataSource, RemoteDataSource {
  ApiLoyaltyDataSource(this._client);

  final ApiClient _client;

  @override
  Future<LoyaltyAccount> fetchAccount(LoyaltyContext context) async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/reservations/${context.reservationId}/loyalty',
    );
    final Map<String, Object?> data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
    return LoyaltyAccountModel(data).toEntity();
  }

  @override
  Future<LoyaltyProgram> fetchProgram(String hotelId) async {
    final Map<String, dynamic> json =
        await _client.getJson('/guest/hotels/$hotelId/loyalty');
    final Map<String, Object?> data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
    return LoyaltyProgramModel(data).toEntity();
  }

  @override
  Future<List<LoyaltyTransaction>> fetchTransactions(
    LoyaltyContext context,
  ) async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/reservations/${context.reservationId}/loyalty/transactions',
    );
    final List<Object?> data = (json['data'] as List<Object?>?) ?? const <Object?>[];
    return data
        .whereType<Map<String, Object?>>()
        .map((Map<String, Object?> j) => LoyaltyTransactionModel(j).toEntity())
        .toList(growable: false);
  }

  @override
  Future<RedeemPointsResult> redeem(
    RedeemPointsRequest request,
    LoyaltyContext context,
  ) async {
    try {
      final Map<String, dynamic> json = await _client.postJson(
        '/guest/reservations/${request.reservationId}/loyalty/redeem',
        body: RedeemLoyaltyPayload(request.points).toJson(),
        headers: <String, String>{'Idempotency-Key': request.idempotencyKey},
      );
      final Map<String, Object?> data =
          (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
      return RedeemPointsResult(
        outcome: LoyaltyRedeemOutcome.redeemed,
        transaction: LoyaltyTransactionModel(data).toEntity(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final Object? body = e.response?.data;
        final Object? fieldErrors = body is Map ? body['errors'] : null;
        // Plain FormRequest validation (points min:1/max:10000000) — a field
        // error map, not a business `reason`.
        if (fieldErrors is Map && fieldErrors['points'] is List) {
          return const RedeemPointsResult(outcome: LoyaltyRedeemOutcome.invalidAmount);
        }
        final String? reason = fieldErrors is Map ? fieldErrors['reason'] as String? : null;
        return RedeemPointsResult(outcome: _redeemOutcomeFromReason(reason));
      }
      rethrow;
    }
  }

  static LoyaltyRedeemOutcome _redeemOutcomeFromReason(String? reason) {
    if (reason == null) return LoyaltyRedeemOutcome.notEligible;
    if (reason == 'already_redeemed_against_this_booking') {
      return LoyaltyRedeemOutcome.alreadyRedeemedDifferent;
    }
    if (reason.startsWith('exceeds_maximum_redemption')) {
      return LoyaltyRedeemOutcome.invalidAmount;
    }
    if (reason == 'insufficient_points_balance') {
      return LoyaltyRedeemOutcome.insufficientPoints;
    }
    if (reason == 'loyalty_program_inactive' || reason == 'redeem_rate_not_configured') {
      return LoyaltyRedeemOutcome.programInactive;
    }
    if (reason.startsWith('reservation_not_redeemable')) {
      return LoyaltyRedeemOutcome.notEligible;
    }
    return LoyaltyRedeemOutcome.notEligible;
  }
}
