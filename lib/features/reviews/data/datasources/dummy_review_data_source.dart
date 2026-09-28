import '../../../../core/data/data_source.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/review_draft.dart';
import '../../domain/entities/submit_review.dart';
import '../../domain/entities/review_category.dart';
import 'review_data_source.dart';

/// A deterministic review scenario, chosen purely from the reservation id.
enum DummyReviewScenario {
  /// No review yet; a submit lands in moderation (`pending`).
  noReviewThenPending,

  /// No review yet; a submit is auto-approved (`published`).
  noReviewThenPublished,

  /// A review already exists and is awaiting moderation.
  alreadyReviewedPending,

  /// A review already exists and was rejected by moderation.
  alreadyReviewedRejected,
}

/// Deterministic, offline reviews source used while **no backend review domain
/// exists at all**.
///
/// Guarantees required by the phase brief:
/// * no network, no timers, no randomness, no `DateTime.now()` branching (a
///   `clock` is injected for the entry timestamp only);
/// * the scenario is a pure function of the reservation id ([scenarioFor]);
/// * `submit` is idempotent — a second submit for a reservation that already
///   has a review returns the existing one ([ReviewSubmitOutcome.alreadyReviewed]),
///   never a duplicate;
/// * the app never assumes publication — the returned [Review.status] is what
///   the UI reads.
///
/// [failWith] is a test seam.
class DummyReviewDataSource implements ReviewDataSource, DummyDataSource {
  DummyReviewDataSource({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, Review> _byReservation = <String, Review>{};

  /// When non-null, the next call throws this instead.
  Object? failWith;

  static DummyReviewScenario scenarioFor(String reservationId) {
    switch (_fnv1a(reservationId) % 4) {
      case 0:
        return DummyReviewScenario.noReviewThenPending;
      case 1:
        return DummyReviewScenario.noReviewThenPublished;
      case 2:
        return DummyReviewScenario.alreadyReviewedPending;
      default:
        return DummyReviewScenario.alreadyReviewedRejected;
    }
  }

  Review? _seededReviewFor(String reservationId) {
    final DummyReviewScenario scenario = scenarioFor(reservationId);
    switch (scenario) {
      case DummyReviewScenario.alreadyReviewedPending:
        return Review(
          id: 'seed-review-$reservationId',
          reservationId: reservationId,
          rating: 4,
          text: 'Comfortable room and a smooth check-in.',
          status: ReviewStatus.pending,
          createdAt: _clock().subtract(const Duration(days: 2)),
        );
      case DummyReviewScenario.alreadyReviewedRejected:
        return Review(
          id: 'seed-review-$reservationId',
          reservationId: reservationId,
          rating: 2,
          text: null,
          status: ReviewStatus.rejected,
          createdAt: _clock().subtract(const Duration(days: 3)),
        );
      case DummyReviewScenario.noReviewThenPending:
      case DummyReviewScenario.noReviewThenPublished:
        return null;
    }
  }

  Review? _current(String reservationId) =>
      _byReservation[reservationId] ?? _seededReviewFor(reservationId);

  /// Dummy mode has **no** review categories: they are dashboard-managed per
  /// hotel, and inventing a fixed set here would hardcode them. The dynamic
  /// form is exercised through the API source and its tests.
  @override
  Future<List<ReviewCategory>> fetchCategories(ReviewContext context) async {
    if (failWith != null) throw failWith!;
    return const <ReviewCategory>[];
  }

  @override
  Future<Review?> fetchReview(ReviewContext context) async {
    if (failWith != null) throw failWith!;
    return _current(context.reservationId);
  }

  @override
  Future<SubmitReviewResult> submit(
    SubmitReviewRequest request,
    ReviewContext context,
  ) async {
    if (failWith != null) throw failWith!;

    if (request.rating < ReviewDraft.minRating ||
        request.rating > ReviewDraft.maxRating) {
      return const SubmitReviewResult(
        outcome: ReviewSubmitOutcome.invalidRating,
      );
    }
    if (!context.eligibility.canReview) {
      return const SubmitReviewResult(outcome: ReviewSubmitOutcome.notEligible);
    }

    final Review? existing = _current(request.reservationId);
    if (existing != null) {
      // Persist the seeded one so a later fetch is consistent.
      _byReservation[request.reservationId] = existing;
      return SubmitReviewResult(
        outcome: ReviewSubmitOutcome.alreadyReviewed,
        review: existing,
      );
    }

    final ReviewStatus status =
        scenarioFor(request.reservationId) ==
            DummyReviewScenario.noReviewThenPublished
        ? ReviewStatus.published
        : ReviewStatus.pending;

    final Review review = Review(
      id: 'review-${_fnv1a(request.idempotencyKey) % 900000 + 100000}',
      reservationId: request.reservationId,
      rating: request.rating,
      text: request.text,
      status: status,
      createdAt: _clock(),
    );
    _byReservation[request.reservationId] = review;
    return SubmitReviewResult(
      outcome: ReviewSubmitOutcome.submitted,
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
