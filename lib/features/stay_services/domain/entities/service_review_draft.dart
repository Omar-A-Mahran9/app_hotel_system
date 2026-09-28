import 'package:flutter/foundation.dart';

import 'service_order.dart';
import 'service_order_status.dart';

/// The guest's in-progress service review — a rating and optional text,
/// before it is submitted. Mirrors `ReviewDraft`.
@immutable
class ServiceReviewDraft {
  const ServiceReviewDraft({this.rating = 0, this.text = ''});

  /// 0 means "not chosen yet". A valid submission needs [minRating]–[maxRating].
  final int rating;

  /// Raw text as typed. [normalizedText] is what actually gets submitted.
  final String text;

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

  ServiceReviewDraft copyWith({int? rating, String? text}) =>
      ServiceReviewDraft(rating: rating ?? this.rating, text: text ?? this.text);

  @override
  bool operator ==(Object other) =>
      other is ServiceReviewDraft && other.rating == rating && other.text == text;

  @override
  int get hashCode => Object.hash(rating, text);
}

/// Whether the guest can review this service order, judged from the order
/// status the app already holds. The backend stays authoritative; this is a
/// UX pre-check — only a `fulfilled` order (the delivered state) may be
/// reviewed, the service-level analogue of a hotel review requiring a
/// completed/stayed reservation.
enum ServiceReviewEligibility {
  eligible,
  notFulfilled,
  cancelled;

  static ServiceReviewEligibility fromOrder(ServiceOrderStatus status) {
    return switch (status) {
      ServiceOrderStatus.fulfilled => ServiceReviewEligibility.eligible,
      ServiceOrderStatus.cancelled => ServiceReviewEligibility.cancelled,
      _ => ServiceReviewEligibility.notFulfilled,
    };
  }

  bool get canReview => this == ServiceReviewEligibility.eligible;
}

/// The context the guest app can seed a service review read/submission with.
/// The backend guest endpoint resolves order ownership + eligibility itself.
@immutable
class ServiceReviewContext {
  const ServiceReviewContext({
    required this.reservationId,
    required this.serviceOrderId,
    required this.orderStatus,
  });

  factory ServiceReviewContext.forOrder(ServiceOrder order) => ServiceReviewContext(
        reservationId: order.reservationId,
        serviceOrderId: order.id,
        orderStatus: order.status,
      );

  final String reservationId;
  final String serviceOrderId;
  final ServiceOrderStatus orderStatus;

  ServiceReviewEligibility get eligibility =>
      ServiceReviewEligibility.fromOrder(orderStatus);
}
