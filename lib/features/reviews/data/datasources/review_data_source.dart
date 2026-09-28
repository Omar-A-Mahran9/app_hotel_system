import '../../domain/entities/review.dart';
import '../../domain/entities/review_draft.dart';
import '../../domain/entities/review_category.dart';
import '../../domain/entities/submit_review.dart';

/// The reviews data contract. Dummy + API implementations selected by DI
/// (`AppConfig.useDummyData`), exactly like the other features.
abstract interface class ReviewDataSource {
  Future<Review?> fetchReview(ReviewContext context);

  /// The **active** review categories of the context's hotel, in display
  /// order — dynamic, dashboard-managed; possibly empty.
  Future<List<ReviewCategory>> fetchCategories(ReviewContext context);

  Future<SubmitReviewResult> submit(
    SubmitReviewRequest request,
    ReviewContext context,
  );
}
