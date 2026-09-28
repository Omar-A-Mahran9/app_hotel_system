import 'package:flutter/foundation.dart';

import '../../../reviews/domain/entities/review.dart' show ReviewStatus;

/// A guest's review of one fulfilled service order — independent of the
/// hotel-level `Review` (mobile/docs mirrors backend `App\Domain\StayServices\
/// Models\ServiceReview`: a service review never affects the hotel's own
/// rating, and vice versa). One per service order. Numeric rating 1-5,
/// optional text, the same [ReviewStatus] moderation vocabulary as a hotel
/// review (pending/published/rejected).
@immutable
class ServiceReview {
  const ServiceReview({
    required this.id,
    required this.serviceOrderId,
    required this.rating,
    required this.status,
    this.text,
    this.createdAt,
  });

  final String id;
  final String serviceOrderId;

  /// 1-5, integer.
  final int rating;

  /// Optional free text. Never whitespace-only (trimmed at the boundary).
  final String? text;

  final ReviewStatus status;
  final DateTime? createdAt;

  bool get hasText => text != null && text!.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is ServiceReview &&
      other.id == id &&
      other.serviceOrderId == serviceOrderId &&
      other.rating == rating &&
      other.text == text &&
      other.status == status &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, serviceOrderId, rating, text, status, createdAt);

  @override
  String toString() => 'ServiceReview($id, r$rating, ${status.wireValue})';
}
