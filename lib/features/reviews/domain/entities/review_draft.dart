import 'package:flutter/foundation.dart';

import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/domain/entities/reservation_status.dart';

/// The guest's in-progress review — an overall rating, optional text and
/// optional ratings for the hotel's dynamic review categories, before it is
/// submitted. Validation lives here so the form widget stays dumb.
@immutable
class ReviewDraft {
  const ReviewDraft({
    this.rating = 0,
    this.text = '',
    this.categoryRatings = const <String, int>{},
  });

  /// 0 means "not chosen yet". A valid submission needs [minRating]–[maxRating].
  final int rating;

  /// Raw text as typed. [normalizedText] is what actually gets submitted.
  final String text;

  /// Optional 1-5 ratings keyed by category id — only for the categories the
  /// API returned for this hotel; never a fixed set.
  final Map<String, int> categoryRatings;

  static const int minRating = 1;
  static const int maxRating = 5;

  bool get isRatingChosen => rating >= minRating && rating <= maxRating;

  /// Trimmed text, or `null` when it is empty / whitespace-only — a
  /// whitespace-only body is never submitted.
  String? get normalizedText {
    final String t = text.trim();
    return t.isEmpty ? null : t;
  }

  bool get canSubmit => isRatingChosen;

  ReviewDraft copyWith({
    int? rating,
    String? text,
    Map<String, int>? categoryRatings,
  }) => ReviewDraft(
    rating: rating ?? this.rating,
    text: text ?? this.text,
    categoryRatings: categoryRatings ?? this.categoryRatings,
  );

  /// Sets one category's 1-5 rating.
  ReviewDraft withCategoryRating(String categoryId, int rating) => copyWith(
    categoryRatings: <String, int>{...categoryRatings, categoryId: rating},
  );

  @override
  bool operator ==(Object other) =>
      other is ReviewDraft &&
      other.rating == rating &&
      other.text == text &&
      mapEquals(other.categoryRatings, categoryRatings);

  @override
  int get hashCode => Object.hash(
    rating,
    text,
    Object.hashAllUnordered(
      categoryRatings.entries.map(
        (MapEntry<String, int> e) => '${e.key}:${e.value}',
      ),
    ),
  );
}

/// Whether the guest can review this reservation, judged from the reservation
/// status the app already holds. The backend stays authoritative; this is a UX
/// pre-check.
///
/// A review belongs to a completed/stayed reservation — the same definition the
/// backend `LoyaltyService::COMPLETED_RESERVATION_STATUSES` uses for the
/// "completed stay" concept (Phase 0 §14).
enum ReviewEligibility {
  eligible,
  notCompleted,
  cancelled;

  static ReviewEligibility fromReservation(ReservationStatus status) {
    return switch (status) {
      ReservationStatus.checkedOut ||
      ReservationStatus.invoiced => ReviewEligibility.eligible,
      ReservationStatus.cancelled => ReviewEligibility.cancelled,
      _ => ReviewEligibility.notCompleted,
    };
  }

  bool get canReview => this == ReviewEligibility.eligible;
}

/// The context the guest app can seed a review read/submission with. The future
/// backend guest endpoint resolves reservation ownership + eligibility itself.
@immutable
class ReviewContext {
  const ReviewContext({
    required this.reservationId,
    required this.reservationStatus,
    this.hotelId,
  });

  factory ReviewContext.forReservation(Reservation reservation) =>
      ReviewContext(
        reservationId: reservation.id,
        reservationStatus: reservation.status,
        hotelId: reservation.hotelId,
      );

  final String reservationId;
  final ReservationStatus reservationStatus;

  /// The reservation's hotel, whose dynamic review categories the form
  /// shows. `null` only where categories are never fetched.
  final String? hotelId;

  ReviewEligibility get eligibility =>
      ReviewEligibility.fromReservation(reservationStatus);
}
