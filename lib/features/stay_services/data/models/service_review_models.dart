// Data-transfer models for the service-reviews feature.
//
// Mirrors `review_models.dart`. Real backend contract (Guest
// ServiceReviewController): `id`, `service_order_id`, `rating`, `text`,
// `status`, `created_at`.

import '../../../reviews/domain/entities/review.dart' show ReviewStatus;
import '../../domain/entities/service_review.dart';

typedef Json = Map<String, Object?>;

class ServiceReviewModel {
  const ServiceReviewModel(this._json);
  final Json _json;

  ServiceReview toEntity() {
    final Object? rawText = _json['text'];
    final String? text = rawText is String && rawText.trim().isNotEmpty
        ? rawText.trim()
        : null;
    final Object? rawDate = _json['created_at'];
    return ServiceReview(
      id: '${_json['id']}',
      serviceOrderId: '${_json['service_order_id']}',
      rating: (_json['rating'] as num?)?.toInt() ?? 0,
      text: text,
      status: ReviewStatus.fromWire(_json['status'] as String?),
      createdAt: rawDate is String && rawDate.isNotEmpty
          ? DateTime.tryParse(rawDate)
          : null,
    );
  }
}

/// The submit request body, matching `SubmitServiceReviewRequest` (backend).
class SubmitServiceReviewPayload {
  const SubmitServiceReviewPayload({required this.rating, this.text});

  final int rating;
  final String? text;

  Json toJson() => <String, Object?>{
        'rating': rating,
        if (text != null) 'text': text,
      };
}
