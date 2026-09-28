import 'package:dio/dio.dart';

import '../../../../core/data/data_source.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/service_review.dart';
import '../../domain/entities/service_review_draft.dart';
import '../../domain/entities/submit_service_review.dart';
import '../models/service_review_models.dart';
import 'service_review_data_source.dart';

/// API-backed service-reviews source.
///
/// Real, authenticated guest contract (`GuestServiceReviewController`):
///
/// `GET  /guest/reservations/{reservation}/service-orders/{serviceOrder}/review`
/// → 200 `ServiceReviewResource` | 404 (none yet)
/// `POST /guest/reservations/{reservation}/service-orders/{serviceOrder}/review`
/// (`{rating, text?}`) → 201 (new) | 200 (existing — duplicate-submit rule)
/// `ServiceReviewResource`
///
/// Eligibility (order must be `fulfilled`) / ownership / duplicate /
/// moderation are all resolved server-side, mirroring [ApiReviewDataSource].
class ApiServiceReviewDataSource
    implements ServiceReviewDataSource, RemoteDataSource {
  ApiServiceReviewDataSource(this._client);

  final ApiClient _client;

  @override
  Future<ServiceReview?> fetchReview(ServiceReviewContext context) async {
    try {
      final Map<String, dynamic> json = await _client.getJson(
        '/guest/reservations/${context.reservationId}/service-orders/'
        '${context.serviceOrderId}/review',
      );
      final Object? data = json['data'];
      if (data is! Map<String, Object?>) return null;
      return ServiceReviewModel(data).toEntity();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<SubmitServiceReviewResult> submit(
    SubmitServiceReviewRequest request,
    ServiceReviewContext context,
  ) async {
    try {
      final (Map<String, dynamic> json, int? statusCode) =
          await _client.postJsonWithStatus(
        '/guest/reservations/${request.reservationId}/service-orders/'
        '${request.serviceOrderId}/review',
        body: SubmitServiceReviewPayload(rating: request.rating, text: request.text)
            .toJson(),
      );
      final Map<String, Object?> data = _dataOf(json);
      return SubmitServiceReviewResult(
        outcome: statusCode == 201
            ? ServiceReviewSubmitOutcome.submitted
            : ServiceReviewSubmitOutcome.alreadyReviewed,
        review: ServiceReviewModel(data).toEntity(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final Object? body = e.response?.data;
        final Object? errors = body is Map ? body['errors'] : null;
        if (errors is Map && errors['rating'] is List) {
          return const SubmitServiceReviewResult(
            outcome: ServiceReviewSubmitOutcome.invalidRating,
          );
        }
        // Any other 422 here is `ServiceReviewNotAllowedException` —
        // currently only `service_order_not_fulfilled:*`.
        return const SubmitServiceReviewResult(
          outcome: ServiceReviewSubmitOutcome.notEligible,
        );
      }
      rethrow;
    }
  }

  Map<String, Object?> _dataOf(Map<String, dynamic> json) =>
      (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
}
