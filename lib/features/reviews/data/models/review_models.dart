// Data-transfer models for the reviews feature — the guest review endpoints:
// a review is `id`, `reservation_id`, `rating`, `text`, `status`,
// `created_at` and `category_ratings[{category_id, label, rating}]`; a review
// category is `{id, label, description, icon}` (dynamic, per hotel).

import '../../domain/entities/review_category.dart';
import '../../domain/entities/review.dart';

typedef Json = Map<String, Object?>;

class ReviewModel {
  const ReviewModel(this._json);
  final Json _json;

  Review toEntity() {
    final Object? rawText = _json['text'];
    final String? text = rawText is String && rawText.trim().isNotEmpty
        ? rawText.trim()
        : null;
    final Object? rawDate = _json['created_at'];
    return Review(
      id: '${_json['id']}',
      reservationId: '${_json['reservation_id']}',
      rating: (_json['rating'] as num?)?.toInt() ?? 0,
      text: text,
      status: ReviewStatus.fromWire(_json['status'] as String?),
      createdAt: rawDate is String && rawDate.isNotEmpty
          ? DateTime.tryParse(rawDate)
          : null,
      categoryRatings: <ReviewCategoryRating>[
        for (final Object? raw
            in (_json['category_ratings'] as List<Object?>?) ??
                const <Object?>[])
          if (raw is Map && raw['category_id'] != null && raw['rating'] is num)
            ReviewCategoryRating(
              categoryId: '${raw['category_id']}',
              label: (raw['label'] as String?) ?? '',
              rating: (raw['rating'] as num).toInt(),
            ),
      ],
    );
  }
}

/// The submit request body, as far as the expected contract goes.
class SubmitReviewPayload {
  const SubmitReviewPayload({
    required this.rating,
    this.text,
    this.categoryRatings = const <String, int>{},
  });

  final int rating;
  final String? text;

  /// Category id → rating, sent as `category_ratings[{category_id, rating}]`.
  final Map<String, int> categoryRatings;

  Json toJson() => <String, Object?>{
    'rating': rating,
    if (text != null) 'text': text,
    if (categoryRatings.isNotEmpty)
      'category_ratings': <Json>[
        for (final MapEntry<String, int> e in categoryRatings.entries)
          <String, Object?>{
            'category_id': int.tryParse(e.key) ?? e.key,
            'rating': e.value,
          },
      ],
  };
}

/// One entry of `GET /guest/hotels/{hotel}/review-categories`.
class ReviewCategoryModel {
  const ReviewCategoryModel(this._json);
  final Json _json;

  ReviewCategory? toEntity() {
    final Object? id = _json['id'];
    final Object? label = _json['label'] ?? _json['name'];
    if (id == null || label is! String || label.isEmpty) return null;
    return ReviewCategory(
      id: '$id',
      label: label,
      description: _json['description'] as String?,
      icon: _json['icon'] as String?,
    );
  }
}
