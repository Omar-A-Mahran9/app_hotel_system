import '../entities/service_review.dart';
import '../entities/service_review_draft.dart';
import '../entities/submit_service_review.dart';

/// The service-reviews contract the presentation layer depends on. Mirrors
/// `ReviewRepository`.
abstract interface class ServiceReviewRepository {
  /// The guest's existing review for a service order, or `null` when none.
  Future<ServiceReview?> reviewFor(ServiceReviewContext context);

  /// Submits a review. Idempotent — a second submit for a service order that
  /// already has one returns the existing review.
  Future<SubmitServiceReviewResult> submit(
    SubmitServiceReviewRequest request,
    ServiceReviewContext context,
  );
}
