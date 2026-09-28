import 'package:dio/dio.dart';

import '../../../../core/data/data_source.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/review_draft.dart';
import '../../domain/entities/submit_review.dart';
import '../models/review_models.dart';
import '../../domain/entities/review_category.dart';
import 'review_data_source.dart';

/// API-backed reviews source.
///
/// The Reviews domain now exists end-to-end on the backend (model,
/// migration, service, policy, guest + staff controllers — see
/// `App\Domain\Review`), built directly from
/// `mobile/docs/mobile-phase-10-loyalty-reviews.md`:
///
/// `GET  /guest/reservations/{reservation}/review` → 200 `ReviewResource` |
/// 404 (none yet)
/// `POST /guest/reservations/{reservation}/review` (`{rating, text?}`) →
/// 201 (new) | 200 (existing — the doc's "return the existing one" duplicate
/// rule) `ReviewResource`
///
/// Eligibility/ownership/duplicate/moderation are all resolved server-side.
/// `ReviewNotAllowedException` (ineligible reservation) now carries a machine
/// `errors.reason` (added alongside the loyalty one), so [submit] classifies
/// the real outcome instead of guessing from localized text.
class ApiReviewDataSource implements ReviewDataSource, RemoteDataSource {
  ApiReviewDataSource(this._client);

  final ApiClient _client;

  @override
  Future<Review?> fetchReview(ReviewContext context) async {
    try {
      final Map<String, dynamic> json = await _client.getJson(
        '/guest/reservations/${context.reservationId}/review',
      );
      final Object? data = json['data'];
      if (data is! Map<String, Object?>) return null;
      return ReviewModel(data).toEntity();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<SubmitReviewResult> submit(
    SubmitReviewRequest request,
    ReviewContext context,
  ) async {
    try {
      final (Map<String, dynamic> json, int? statusCode) = await _client
          .postJsonWithStatus(
            '/guest/reservations/${request.reservationId}/review',
            body: SubmitReviewPayload(
              rating: request.rating,
              text: request.text,
              categoryRatings: request.categoryRatings,
            ).toJson(),
          );
      final Map<String, Object?> data = _dataOf(json);
      return SubmitReviewResult(
        outcome: statusCode == 201
            ? ReviewSubmitOutcome.submitted
            : ReviewSubmitOutcome.alreadyReviewed,
        review: ReviewModel(data).toEntity(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final Object? body = e.response?.data;
        final Object? errors = body is Map ? body['errors'] : null;
        if (errors is Map && errors['rating'] is List) {
          return const SubmitReviewResult(
            outcome: ReviewSubmitOutcome.invalidRating,
          );
        }
        // Any other 422 here is `ReviewNotAllowedException` — currently only
        // `reservation_not_completed:*` (see ReviewNotAllowedException).
        return const SubmitReviewResult(
          outcome: ReviewSubmitOutcome.notEligible,
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<ReviewCategory>> fetchCategories(ReviewContext context) async {
    final String? hotelId = context.hotelId;
    if (hotelId == null) return const <ReviewCategory>[];
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/hotels/$hotelId/review-categories',
    );
    final Object? data = json['data'];
    if (data is! List) return const <ReviewCategory>[];
    return <ReviewCategory>[
      for (final Object? raw in data)
        if (raw is Map<String, Object?>) ?ReviewCategoryModel(raw).toEntity(),
    ];
  }

  Map<String, Object?> _dataOf(Map<String, dynamic> json) =>
      (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
}
