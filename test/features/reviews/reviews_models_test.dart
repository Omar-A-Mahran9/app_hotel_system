import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/reviews/data/models/review_models.dart';
import 'package:hotel_guest_app/features/reviews/domain/entities/review.dart';

void main() {
  group('ReviewModel', () {
    test('maps the expected guest-review shape', () {
      final review = ReviewModel(<String, Object?>{
        'id': 12,
        'reservation_id': 'r1',
        'rating': 5,
        'text': '  Lovely stay  ',
        'status': 'published',
        'created_at': '2026-09-02T10:00:00Z',
      }).toEntity();
      expect(review.id, '12');
      expect(review.reservationId, 'r1');
      expect(review.rating, 5);
      expect(review.text, 'Lovely stay'); // trimmed
      expect(review.status, ReviewStatus.published);
      expect(review.createdAt, isNotNull);
    });

    test('blank text becomes null; an unknown status defaults to pending', () {
      final review = ReviewModel(<String, Object?>{
        'id': 1,
        'reservation_id': 'r1',
        'rating': 3,
        'text': '   ',
        'status': 'quarantined',
      }).toEntity();
      expect(review.text, isNull);
      expect(review.status, ReviewStatus.pending);
      expect(review.createdAt, isNull);
    });
  });

  group('SubmitReviewPayload', () {
    test('only sends rating + text; omits text entirely when absent', () {
      expect(const SubmitReviewPayload(rating: 4, text: 'nice').toJson(),
          <String, Object?>{'rating': 4, 'text': 'nice'});
      expect(const SubmitReviewPayload(rating: 4).toJson(),
          <String, Object?>{'rating': 4});
    });
  });
}
