import 'package:flutter/foundation.dart';

import 'service_review.dart';
import 'service_review_draft.dart';

/// A request to submit a review for one service order. Mirrors
/// `SubmitReviewRequest`. No sub-ratings. The backend resolves order
/// ownership + eligibility.
@immutable
class SubmitServiceReviewRequest {
  const SubmitServiceReviewRequest({
    required this.reservationId,
    required this.serviceOrderId,
    required this.rating,
    this.text,
  });

  factory SubmitServiceReviewRequest.fromDraft(
    ServiceReviewContext context,
    ServiceReviewDraft draft,
  ) =>
      SubmitServiceReviewRequest(
        reservationId: context.reservationId,
        serviceOrderId: context.serviceOrderId,
        rating: draft.rating,
        text: draft.normalizedText,
      );

  final String reservationId;
  final String serviceOrderId;
  final int rating;
  final String? text;

  /// Rebuild the editable draft this request came from — used to re-seed the
  /// form / a retry without re-reading any widget state.
  ServiceReviewDraft toDraft() =>
      ServiceReviewDraft(rating: rating, text: text ?? '');

  /// Stable key for local duplicate-submit dedupe.
  String get idempotencyKey =>
      'service_review:$serviceOrderId:$rating:${text ?? '-'}';

  @override
  bool operator ==(Object other) =>
      other is SubmitServiceReviewRequest &&
      other.reservationId == reservationId &&
      other.serviceOrderId == serviceOrderId &&
      other.rating == rating &&
      other.text == text;

  @override
  int get hashCode =>
      Object.hash(reservationId, serviceOrderId, rating, text);

  @override
  String toString() => 'SubmitServiceReviewRequest($serviceOrderId, r$rating)';
}

/// The safe, client-visible outcome of a submit attempt.
enum ServiceReviewSubmitOutcome {
  /// The review was accepted. Its [ServiceReview.status] says whether it is
  /// pending moderation or already published.
  submitted,

  /// A review for this service order already exists — the existing one is
  /// returned (not an error).
  alreadyReviewed,

  /// The backend refused: the service order is not `fulfilled`.
  notEligible,

  /// The rating was outside 1–5.
  invalidRating;

  bool get isSuccess =>
      this == ServiceReviewSubmitOutcome.submitted ||
      this == ServiceReviewSubmitOutcome.alreadyReviewed;
}

@immutable
class SubmitServiceReviewResult {
  const SubmitServiceReviewResult({required this.outcome, this.review});

  final ServiceReviewSubmitOutcome outcome;

  /// Present for [ServiceReviewSubmitOutcome.submitted] / [alreadyReviewed].
  final ServiceReview? review;

  @override
  bool operator ==(Object other) =>
      other is SubmitServiceReviewResult &&
      other.outcome == outcome &&
      other.review == review;

  @override
  int get hashCode => Object.hash(outcome, review);
}
