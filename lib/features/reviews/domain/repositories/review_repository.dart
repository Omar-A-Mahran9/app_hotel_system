import '../entities/review.dart';
import '../entities/review_draft.dart';
import '../entities/review_category.dart';
import '../entities/submit_review.dart';

/// The reviews contract the presentation layer depends on. Dummy vs API is a DI
/// decision, exactly as in the other features.
///
/// Infrastructure errors are thrown as a `Failure` (mapped by the impl).
/// **Business** outcomes (not eligible, already reviewed, invalid rating) are
/// returned on [SubmitReviewResult] — never a false success. The backend stays
/// authoritative for eligibility, ownership, duplicates and moderation.
abstract interface class ReviewRepository {
  /// The guest's existing review for a reservation, or `null` when none.
  Future<Review?> reviewFor(ReviewContext context);

  /// The hotel's active, dashboard-managed review categories (may be empty).
  Future<List<ReviewCategory>> categoriesFor(ReviewContext context);

  /// Submits a review. Idempotent — a second submit for a reservation that
  /// already has one returns the existing review.
  Future<SubmitReviewResult> submit(
    SubmitReviewRequest request,
    ReviewContext context,
  );
}
