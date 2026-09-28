import 'package:flutter/foundation.dart';

import 'review.dart';
import 'review_draft.dart';

/// A request to submit a review for a reservation: numeric `rating` (1–5),
/// optional `text`, and optional ratings for the hotel's **dynamic** review
/// categories (ids from the API, never hardcoded). The backend resolves
/// reservation ownership, eligibility and which categories are valid.
@immutable
class SubmitReviewRequest {
  const SubmitReviewRequest({
    required this.reservationId,
    required this.rating,
    this.text,
    this.categoryRatings = const <String, int>{},
  });

  factory SubmitReviewRequest.fromDraft(
    String reservationId,
    ReviewDraft draft,
  ) => SubmitReviewRequest(
    reservationId: reservationId,
    rating: draft.rating,
    text: draft.normalizedText,
    categoryRatings: Map<String, int>.unmodifiable(draft.categoryRatings),
  );

  final String reservationId;
  final int rating;
  final String? text;

  /// Category id → 1-5 rating for the hotel's dynamic review categories.
  final Map<String, int> categoryRatings;

  /// Rebuild the editable draft this request came from — used to re-seed the
  /// form / a retry without re-reading any widget state.
  ReviewDraft toDraft() => ReviewDraft(
    rating: rating,
    text: text ?? '',
    categoryRatings: categoryRatings,
  );

  /// Stable key for local duplicate-submit dedupe. The ratings + text are
  /// part of it so an edited submission is a distinct operation; no time /
  /// random.
  String get idempotencyKey => categoryRatings.isEmpty
      ? 'review:$reservationId:$rating:${text ?? '-'}'
      : 'review:$reservationId:$rating:${text ?? '-'}:$_categoryKey';

  /// Category ratings in a stable (sorted) order.
  String get _categoryKey => (categoryRatings.keys.toList()..sort())
      .map((String k) => '$k=${categoryRatings[k]}')
      .join(',');

  @override
  bool operator ==(Object other) =>
      other is SubmitReviewRequest &&
      other.reservationId == reservationId &&
      other.rating == rating &&
      other.text == text &&
      mapEquals(other.categoryRatings, categoryRatings);

  @override
  int get hashCode => Object.hash(reservationId, rating, text, _categoryKey);

  @override
  String toString() => 'SubmitReviewRequest($reservationId, r$rating)';
}

/// The safe, client-visible outcome of a submit attempt.
enum ReviewSubmitOutcome {
  /// The review was accepted. Its [Review.status] says whether it is pending
  /// moderation or already published — the UI must not claim it is live unless
  /// the status says so.
  submitted,

  /// A review for this reservation already exists — the existing one is
  /// returned (not an error).
  alreadyReviewed,

  /// The backend refused: the reservation is not a completed/stayed booking.
  notEligible,

  /// The rating was outside 1–5.
  invalidRating;

  bool get isSuccess =>
      this == ReviewSubmitOutcome.submitted ||
      this == ReviewSubmitOutcome.alreadyReviewed;
}

@immutable
class SubmitReviewResult {
  const SubmitReviewResult({required this.outcome, this.review});

  final ReviewSubmitOutcome outcome;

  /// Present for [ReviewSubmitOutcome.submitted] / [alreadyReviewed].
  final Review? review;

  @override
  bool operator ==(Object other) =>
      other is SubmitReviewResult &&
      other.outcome == outcome &&
      other.review == review;

  @override
  int get hashCode => Object.hash(outcome, review);
}
