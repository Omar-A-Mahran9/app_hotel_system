import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/service_review.dart';
import '../../domain/entities/service_review_draft.dart';
import '../../domain/entities/submit_service_review.dart';
import '../../domain/repositories/service_review_repository.dart';
import '../datasources/service_review_data_source.dart';

/// Coordinates the service-reviews data source. Mirrors `ReviewRepositoryImpl`.
class ServiceReviewRepositoryImpl implements ServiceReviewRepository {
  ServiceReviewRepositoryImpl(this._dataSource);

  final ServiceReviewDataSource _dataSource;

  @override
  Future<ServiceReview?> reviewFor(ServiceReviewContext context) =>
      _guard(() => _dataSource.fetchReview(context));

  @override
  Future<SubmitServiceReviewResult> submit(
    SubmitServiceReviewRequest request,
    ServiceReviewContext context,
  ) =>
      _guard(() => _dataSource.submit(request, context));

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }
}
