import '../../../../core/data/data_source.dart';
import '../../../reviews/domain/entities/review.dart' show ReviewStatus;
import '../../domain/entities/service_review.dart';
import '../../domain/entities/service_review_draft.dart';
import '../../domain/entities/submit_service_review.dart';
import 'service_review_data_source.dart';

/// A deterministic service-review scenario, chosen purely from the service
/// order id. Mirrors `DummyReviewDataSource`.
enum DummyServiceReviewScenario {
  noReviewThenPending,
  noReviewThenPublished,
  alreadyReviewedPending,
  alreadyReviewedRejected,
}

/// Deterministic, offline service-reviews source.
///
/// Guarantees mirror [DummyReviewDataSource]: no network/timers/randomness,
/// the scenario is a pure function of the service order id, `submit` is
/// idempotent, and the app never assumes publication.
class DummyServiceReviewDataSource
    implements ServiceReviewDataSource, DummyDataSource {
  DummyServiceReviewDataSource({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, ServiceReview> _byOrder = <String, ServiceReview>{};

  Object? failWith;

  static DummyServiceReviewScenario scenarioFor(String serviceOrderId) {
    switch (_fnv1a(serviceOrderId) % 4) {
      case 0:
        return DummyServiceReviewScenario.noReviewThenPending;
      case 1:
        return DummyServiceReviewScenario.noReviewThenPublished;
      case 2:
        return DummyServiceReviewScenario.alreadyReviewedPending;
      default:
        return DummyServiceReviewScenario.alreadyReviewedRejected;
    }
  }

  ServiceReview? _seededReviewFor(String serviceOrderId) {
    final DummyServiceReviewScenario scenario = scenarioFor(serviceOrderId);
    switch (scenario) {
      case DummyServiceReviewScenario.alreadyReviewedPending:
        return ServiceReview(
          id: 'seed-service-review-$serviceOrderId',
          serviceOrderId: serviceOrderId,
          rating: 4,
          text: 'Quick and friendly.',
          status: ReviewStatus.pending,
          createdAt: _clock().subtract(const Duration(days: 1)),
        );
      case DummyServiceReviewScenario.alreadyReviewedRejected:
        return ServiceReview(
          id: 'seed-service-review-$serviceOrderId',
          serviceOrderId: serviceOrderId,
          rating: 2,
          text: null,
          status: ReviewStatus.rejected,
          createdAt: _clock().subtract(const Duration(days: 2)),
        );
      case DummyServiceReviewScenario.noReviewThenPending:
      case DummyServiceReviewScenario.noReviewThenPublished:
        return null;
    }
  }

  ServiceReview? _current(String serviceOrderId) =>
      _byOrder[serviceOrderId] ?? _seededReviewFor(serviceOrderId);

  @override
  Future<ServiceReview?> fetchReview(ServiceReviewContext context) async {
    if (failWith != null) throw failWith!;
    return _current(context.serviceOrderId);
  }

  @override
  Future<SubmitServiceReviewResult> submit(
    SubmitServiceReviewRequest request,
    ServiceReviewContext context,
  ) async {
    if (failWith != null) throw failWith!;

    if (request.rating < ServiceReviewDraft.minRating ||
        request.rating > ServiceReviewDraft.maxRating) {
      return const SubmitServiceReviewResult(
          outcome: ServiceReviewSubmitOutcome.invalidRating);
    }
    if (!context.eligibility.canReview) {
      return const SubmitServiceReviewResult(
          outcome: ServiceReviewSubmitOutcome.notEligible);
    }

    final ServiceReview? existing = _current(request.serviceOrderId);
    if (existing != null) {
      _byOrder[request.serviceOrderId] = existing;
      return SubmitServiceReviewResult(
        outcome: ServiceReviewSubmitOutcome.alreadyReviewed,
        review: existing,
      );
    }

    final ReviewStatus status =
        scenarioFor(request.serviceOrderId) ==
                DummyServiceReviewScenario.noReviewThenPublished
            ? ReviewStatus.published
            : ReviewStatus.pending;

    final ServiceReview review = ServiceReview(
      id: 'service-review-${_fnv1a(request.idempotencyKey) % 900000 + 100000}',
      serviceOrderId: request.serviceOrderId,
      rating: request.rating,
      text: request.text,
      status: status,
      createdAt: _clock(),
    );
    _byOrder[request.serviceOrderId] = review;
    return SubmitServiceReviewResult(
      outcome: ServiceReviewSubmitOutcome.submitted,
      review: review,
    );
  }

  static int _fnv1a(String value) {
    int hash = 0x811c9dc5;
    for (final int unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
