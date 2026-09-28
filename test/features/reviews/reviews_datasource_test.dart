import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/reviews/data/datasources/dummy_review_data_source.dart';
import 'package:hotel_guest_app/features/reviews/domain/entities/review.dart';
import 'package:hotel_guest_app/features/reviews/domain/entities/review_draft.dart';
import 'package:hotel_guest_app/features/reviews/domain/entities/submit_review.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';

import 'reviews_test_support.dart';

void main() {
  final DateTime now = DateTime(2026, 9, 8, 11);
  DummyReviewDataSource source() => DummyReviewDataSource(clock: () => now);

  SubmitReviewRequest req(String id, {int rating = 4, String? text}) =>
      SubmitReviewRequest(reservationId: id, rating: rating, text: text);

  group('DummyReviewDataSource — no review yet', () {
    test('fetchReview is null; a submit lands in moderation (pending)',
        () async {
      final id = reviewScenarioId(DummyReviewScenario.noReviewThenPending);
      final s = source();
      expect(await s.fetchReview(fakeReviewContext(reservationId: id)), isNull);

      final result =
          await s.submit(req(id), fakeReviewContext(reservationId: id));
      expect(result.outcome, ReviewSubmitOutcome.submitted);
      expect(result.review!.status, ReviewStatus.pending);

      // Now consistently readable.
      final fetched =
          await s.fetchReview(fakeReviewContext(reservationId: id));
      expect(fetched!.id, result.review!.id);
    });

    test('the auto-approve scenario returns a published review', () async {
      final id = reviewScenarioId(DummyReviewScenario.noReviewThenPublished);
      final result = await source()
          .submit(req(id), fakeReviewContext(reservationId: id));
      expect(result.outcome, ReviewSubmitOutcome.submitted);
      expect(result.review!.status, ReviewStatus.published);
    });

    test('a second submit for the same reservation is an idempotent replay',
        () async {
      final id = reviewScenarioId(DummyReviewScenario.noReviewThenPending);
      final s = source();
      final first = await s.submit(req(id), fakeReviewContext(reservationId: id));
      final second =
          await s.submit(req(id, rating: 2), fakeReviewContext(reservationId: id));
      expect(second.outcome, ReviewSubmitOutcome.alreadyReviewed);
      expect(second.review!.id, first.review!.id);
      expect(second.review!.rating, first.review!.rating); // unchanged
    });
  });

  group('DummyReviewDataSource — a review already exists', () {
    test('a pending seeded review is returned and blocks a new submit',
        () async {
      final id = reviewScenarioId(DummyReviewScenario.alreadyReviewedPending);
      final s = source();
      final existing =
          await s.fetchReview(fakeReviewContext(reservationId: id));
      expect(existing!.status, ReviewStatus.pending);

      final result =
          await s.submit(req(id), fakeReviewContext(reservationId: id));
      expect(result.outcome, ReviewSubmitOutcome.alreadyReviewed);
      expect(result.review!.id, existing.id);
    });

    test('a rejected seeded review is surfaced as rejected', () async {
      final id = reviewScenarioId(DummyReviewScenario.alreadyReviewedRejected);
      final existing =
          await source().fetchReview(fakeReviewContext(reservationId: id));
      expect(existing!.status, ReviewStatus.rejected);
    });
  });

  group('DummyReviewDataSource — validation + eligibility', () {
    test('a rating outside 1–5 is invalidRating', () async {
      final id = reviewScenarioId(DummyReviewScenario.noReviewThenPending);
      final result = await source().submit(
        req(id, rating: 7),
        fakeReviewContext(reservationId: id),
      );
      expect(result.outcome, ReviewSubmitOutcome.invalidRating);
    });

    test('a non-completed stay is not eligible', () async {
      final id = reviewScenarioId(DummyReviewScenario.noReviewThenPending);
      final result = await source().submit(
        req(id),
        fakeReviewContext(
            reservationId: id, status: ReservationStatus.checkedIn),
      );
      expect(result.outcome, ReviewSubmitOutcome.notEligible);
    });

    test('optional text is persisted when provided', () async {
      final id = reviewScenarioId(DummyReviewScenario.noReviewThenPending);
      final result = await source().submit(
        req(id, text: 'Great pillows'),
        fakeReviewContext(reservationId: id),
      );
      expect(result.review!.text, 'Great pillows');
    });
  });

  group('DummyReviewDataSource — failWith seam', () {
    test('surfaces the error from both methods', () async {
      final s = source()..failWith = const NetworkException();
      await expectLater(
          s.fetchReview(fakeReviewContext()), throwsA(isA<NetworkException>()));
      await expectLater(
        s.submit(const SubmitReviewRequest(reservationId: 'x', rating: 4),
            fakeReviewContext()),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // `ApiReviewDataSource` is now a real implementation against the new
  // Reviews domain — see
  // test/features/reviews/api_review_data_source_test.dart.

  group('ReviewDraft constants', () {
    test('match the documented 1–5 range', () {
      expect(ReviewDraft.minRating, 1);
      expect(ReviewDraft.maxRating, 5);
    });
  });
}
