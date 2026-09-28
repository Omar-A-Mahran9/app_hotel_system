import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/review_draft.dart';
import '../../domain/entities/submit_review.dart';
import '../../domain/repositories/review_repository.dart';
import '../../domain/entities/review_category.dart';
import '../datasources/review_data_source.dart';

/// Coordinates the reviews data source. Dummy vs API is a DI decision. Every
/// *infrastructure* error is mapped to a `Failure` via [ErrorMapper];
/// **business** outcomes ride on [SubmitReviewResult] and pass straight through
/// (never a false success). The backend stays authoritative for eligibility,
/// ownership, duplicates and moderation.
class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._dataSource);

  final ReviewDataSource _dataSource;

  @override
  Future<Review?> reviewFor(ReviewContext context) =>
      _guard(() => _dataSource.fetchReview(context));

  @override
  Future<List<ReviewCategory>> categoriesFor(ReviewContext context) =>
      _guard(() => _dataSource.fetchCategories(context));

  @override
  Future<SubmitReviewResult> submit(
    SubmitReviewRequest request,
    ReviewContext context,
  ) => _guard(() => _dataSource.submit(request, context));

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }
}
