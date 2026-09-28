import '../../domain/entities/service_review.dart';
import '../../domain/entities/service_review_draft.dart';
import '../../domain/entities/submit_service_review.dart';

/// The service-reviews data contract. Dummy + API implementations selected by
/// DI (`AppConfig.useDummyData`), exactly like the other features.
abstract interface class ServiceReviewDataSource {
  Future<ServiceReview?> fetchReview(ServiceReviewContext context);

  Future<SubmitServiceReviewResult> submit(
    SubmitServiceReviewRequest request,
    ServiceReviewContext context,
  );
}
