import 'package:flutter/foundation.dart';

/// A hotel's live guest-rating summary (`review_summary` on
/// `GET /guest/hotels/{hotel}`): the published overall average and count,
/// and one [ReviewCategoryScore] per **active, dashboard-managed** review
/// category of that hotel.
///
/// Fully dynamic — the categories' number, names and order come from the
/// backend; nothing here (or in the UI) assumes any category. Averages are
/// computed server-side from published guest reviews; the app never
/// fabricates one (dummy mode has no summary at all).
@immutable
class HotelReviewSummary {
  const HotelReviewSummary({
    required this.average,
    required this.count,
    required this.categories,
  });

  /// Published overall average (1-5), `null` while there are no reviews.
  final double? average;

  /// Number of published reviews.
  final int count;

  /// Active categories in display order (some may be unrated yet).
  final List<ReviewCategoryScore> categories;

  /// Categories that have at least one rating — the ones worth a bar.
  List<ReviewCategoryScore> get ratedCategories => categories
      .where((ReviewCategoryScore c) => c.average != null && c.ratingsCount > 0)
      .toList(growable: false);

  /// Whether there is anything real to show.
  bool get hasContent => count > 0 || ratedCategories.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is HotelReviewSummary &&
      other.average == average &&
      other.count == count &&
      listEquals(other.categories, categories);

  @override
  int get hashCode => Object.hash(average, count, Object.hashAll(categories));
}

/// One review category's live aggregate for a hotel.
@immutable
class ReviewCategoryScore {
  const ReviewCategoryScore({
    required this.id,
    required this.label,
    required this.ratingsCount,
    this.average,
    this.icon,
  });

  final String id;

  /// Display name, already resolved by the backend for the request locale.
  final String label;

  /// Average of published ratings (1-5), `null` while unrated.
  final double? average;

  final int ratingsCount;

  /// Optional icon key set in the dashboard.
  final String? icon;

  @override
  bool operator ==(Object other) =>
      other is ReviewCategoryScore &&
      other.id == id &&
      other.label == label &&
      other.average == average &&
      other.ratingsCount == ratingsCount &&
      other.icon == icon;

  @override
  int get hashCode => Object.hash(id, label, average, ratingsCount, icon);
}
