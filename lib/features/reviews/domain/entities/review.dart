import 'package:flutter/foundation.dart';

import 'review_category.dart';

/// The moderation state of a guest review.
///
/// There is **no backend review domain in the MVP** — this vocabulary is the
/// contract the mobile app needs and that a future guest review endpoint must
/// provide (see `mobile/docs/mobile-phase-10-loyalty-reviews.md`). The app
/// never assumes a review is publicly visible: only [published] means "live".
enum ReviewStatus {
  /// Submitted, awaiting moderation. NOT publicly visible.
  pending('pending'),

  /// Approved by moderation and live.
  published('published'),

  /// Rejected by moderation. The guest may be allowed to submit again — the
  /// backend decides.
  rejected('rejected');

  const ReviewStatus(this.wireValue);

  final String wireValue;

  static ReviewStatus fromWire(String? value) {
    for (final ReviewStatus s in ReviewStatus.values) {
      if (s.wireValue == value) return s;
    }
    return ReviewStatus.pending;
  }

  bool get isPending => this == ReviewStatus.pending;
  bool get isPublished => this == ReviewStatus.published;
  bool get isRejected => this == ReviewStatus.rejected;
}

/// A guest review for one completed/stayed reservation.
///
/// One review per eligible reservation. Numeric rating 1–5, optional text.
/// No sub-ratings (room / cleanliness / service / location / staff) — none are
/// in any approved contract.
@immutable
class Review {
  const Review({
    required this.id,
    required this.reservationId,
    required this.rating,
    required this.status,
    this.text,
    this.createdAt,
    this.categoryRatings = const <ReviewCategoryRating>[],
  });

  final String id;
  final String reservationId;

  /// 1–5, integer.
  final int rating;

  /// Optional free text. Never whitespace-only (trimmed at the boundary).
  final String? text;

  final ReviewStatus status;
  final DateTime? createdAt;

  /// Ratings given to the hotel's dynamic review categories (may be empty).
  final List<ReviewCategoryRating> categoryRatings;

  bool get hasText => text != null && text!.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is Review &&
      other.id == id &&
      other.reservationId == reservationId &&
      other.rating == rating &&
      other.text == text &&
      other.status == status &&
      other.createdAt == createdAt &&
      listEquals(other.categoryRatings, categoryRatings);

  @override
  int get hashCode => Object.hash(
    id,
    reservationId,
    rating,
    text,
    status,
    createdAt,
    Object.hashAll(categoryRatings),
  );

  @override
  String toString() => 'Review($id, r$rating, ${status.wireValue})';
}
