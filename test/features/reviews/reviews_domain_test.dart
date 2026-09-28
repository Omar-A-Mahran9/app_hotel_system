import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/reviews/domain/entities/review.dart';
import 'package:hotel_guest_app/features/reviews/domain/entities/review_draft.dart';
import 'package:hotel_guest_app/features/reviews/domain/entities/submit_review.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';

void main() {
  group('ReviewStatus', () {
    test('round-trips; an unknown / null value is treated as pending', () {
      for (final ReviewStatus s in ReviewStatus.values) {
        expect(ReviewStatus.fromWire(s.wireValue), s);
      }
      expect(ReviewStatus.fromWire('flagged'), ReviewStatus.pending);
      expect(ReviewStatus.fromWire(null), ReviewStatus.pending);
      expect(ReviewStatus.published.isPublished, isTrue);
      expect(ReviewStatus.pending.isPending, isTrue);
      expect(ReviewStatus.rejected.isRejected, isTrue);
    });
  });

  group('ReviewDraft validation', () {
    test('a rating outside 1–5 is not submittable', () {
      expect(const ReviewDraft().isRatingChosen, isFalse); // 0 = unset
      expect(const ReviewDraft(rating: 0).canSubmit, isFalse);
      expect(const ReviewDraft(rating: 6).canSubmit, isFalse);
      expect(const ReviewDraft(rating: 1).canSubmit, isTrue);
      expect(const ReviewDraft(rating: 5).canSubmit, isTrue);
    });

    test('text is optional; whitespace-only normalises to null', () {
      expect(const ReviewDraft(rating: 4).normalizedText, isNull);
      expect(const ReviewDraft(rating: 4, text: '   ').normalizedText, isNull);
      expect(const ReviewDraft(rating: 4, text: '  good  ').normalizedText,
          'good');
      expect(const ReviewDraft(rating: 4, text: 'x').canSubmit, isTrue);
    });

    test('copyWith keeps the other field', () {
      const base = ReviewDraft(rating: 3, text: 'a');
      expect(base.copyWith(rating: 5).text, 'a');
      expect(base.copyWith(text: 'b').rating, 3);
    });
  });

  group('ReviewEligibility (UX pre-check mirrors the backend stay concept)', () {
    test('only a completed/stayed reservation can be reviewed', () {
      expect(ReviewEligibility.fromReservation(ReservationStatus.checkedOut),
          ReviewEligibility.eligible);
      expect(ReviewEligibility.fromReservation(ReservationStatus.invoiced),
          ReviewEligibility.eligible);
      expect(ReviewEligibility.fromReservation(ReservationStatus.cancelled),
          ReviewEligibility.cancelled);
      expect(ReviewEligibility.fromReservation(ReservationStatus.checkedIn),
          ReviewEligibility.notCompleted);
      expect(ReviewEligibility.eligible.canReview, isTrue);
      expect(ReviewEligibility.notCompleted.canReview, isFalse);
    });

    test('ReviewContext exposes the eligibility', () {
      const ctx = ReviewContext(
        reservationId: 'r1',
        reservationStatus: ReservationStatus.invoiced,
      );
      expect(ctx.eligibility.canReview, isTrue);
    });
  });

  group('SubmitReviewRequest', () {
    test('is built from a draft, dropping empty text', () {
      final req = SubmitReviewRequest.fromDraft(
        'r1',
        const ReviewDraft(rating: 4, text: '   '),
      );
      expect(req.rating, 4);
      expect(req.text, isNull);
    });

    test('idempotency key includes the rating + text, no time / randomness', () {
      const a = SubmitReviewRequest(reservationId: 'r1', rating: 4, text: 'ok');
      const b = SubmitReviewRequest(reservationId: 'r1', rating: 4, text: 'ok');
      expect(a.idempotencyKey, 'review:r1:4:ok');
      expect(a, b);
      expect(
        a,
        isNot(const SubmitReviewRequest(
            reservationId: 'r1', rating: 5, text: 'ok')),
      );
    });

    test('toDraft round-trips the editable fields', () {
      const req =
          SubmitReviewRequest(reservationId: 'r1', rating: 3, text: 'hi');
      final draft = req.toDraft();
      expect(draft.rating, 3);
      expect(draft.text, 'hi');
      const noText = SubmitReviewRequest(reservationId: 'r1', rating: 3);
      expect(noText.toDraft().text, '');
    });

    test('submitted / alreadyReviewed are the success outcomes', () {
      expect(ReviewSubmitOutcome.submitted.isSuccess, isTrue);
      expect(ReviewSubmitOutcome.alreadyReviewed.isSuccess, isTrue);
      expect(ReviewSubmitOutcome.notEligible.isSuccess, isFalse);
      expect(ReviewSubmitOutcome.invalidRating.isSuccess, isFalse);
    });
  });

  group('Review entity', () {
    test('hasText ignores whitespace-only text', () {
      Review r(String? t) => Review(
            id: '1',
            reservationId: 'r1',
            rating: 4,
            status: ReviewStatus.pending,
            text: t,
          );
      expect(r('good').hasText, isTrue);
      expect(r(null).hasText, isFalse);
      expect(r('   ').hasText, isFalse);
    });
  });
}
