import 'package:flutter/foundation.dart';

/// One criterion a guest rates a stay on (`النظافة`, `الإفطار`, …), defined
/// **per hotel in the dashboard** and fetched from
/// `GET /guest/hotels/{hotel}/review-categories`. The app never hardcodes a
/// category, its id, or how many there are — the review form is built from
/// whatever this list contains (possibly empty).
@immutable
class ReviewCategory {
  const ReviewCategory({
    required this.id,
    required this.label,
    this.description,
    this.icon,
  });

  final String id;

  /// Display name, resolved by the backend for the request locale.
  final String label;
  final String? description;
  final String? icon;

  @override
  bool operator ==(Object other) =>
      other is ReviewCategory &&
      other.id == id &&
      other.label == label &&
      other.description == description &&
      other.icon == icon;

  @override
  int get hashCode => Object.hash(id, label, description, icon);
}

/// A rating a submitted review gave one [ReviewCategory]. [label] is the
/// snapshot taken when the guest rated it (a later rename in the dashboard
/// never rewrites it).
@immutable
class ReviewCategoryRating {
  const ReviewCategoryRating({
    required this.categoryId,
    required this.label,
    required this.rating,
  });

  final String categoryId;
  final String label;
  final int rating;

  @override
  bool operator ==(Object other) =>
      other is ReviewCategoryRating &&
      other.categoryId == categoryId &&
      other.label == label &&
      other.rating == rating;

  @override
  int get hashCode => Object.hash(categoryId, label, rating);
}
