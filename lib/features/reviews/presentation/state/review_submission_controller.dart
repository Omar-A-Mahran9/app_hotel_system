import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/review_draft.dart';
import '../../domain/entities/submit_review.dart';
import 'review_providers.dart';

/// The state of the one-shot "submit review" action.
///
/// The business *outcome* (submitted / already reviewed / not eligible /
/// invalid rating) and the moderation *status* live on the result; this type
/// is only the action's idle / loading / done / failed.
sealed class ReviewActionState {
  const ReviewActionState();

  bool get isSubmitting => this is ReviewSubmitting;

  SubmitReviewRequest? get requestOrNull => switch (this) {
        ReviewSubmitting(:final SubmitReviewRequest request) => request,
        ReviewSubmitDone(:final SubmitReviewRequest request) => request,
        ReviewSubmitFailed(:final SubmitReviewRequest request) => request,
        _ => null,
      };

  SubmitReviewResult? get resultOrNull =>
      this is ReviewSubmitDone ? (this as ReviewSubmitDone).result : null;

  Failure? get failureOrNull => this is ReviewSubmitFailed
      ? (this as ReviewSubmitFailed).failure
      : null;
}

class ReviewIdle extends ReviewActionState {
  const ReviewIdle();
}

class ReviewSubmitting extends ReviewActionState {
  const ReviewSubmitting(this.request);
  final SubmitReviewRequest request;
}

/// The backend resolved the submission. Terminal for a *successful* outcome —
/// a further submit for the same request is ignored (double-tap safe). A
/// blocked outcome (not eligible) is shown from here.
class ReviewSubmitDone extends ReviewActionState {
  const ReviewSubmitDone(this.request, this.result);
  final SubmitReviewRequest request;
  final SubmitReviewResult result;
}

class ReviewSubmitFailed extends ReviewActionState {
  const ReviewSubmitFailed(this.request, this.failure);
  final SubmitReviewRequest request;
  final Failure failure;
}

/// Owns the submit-review action.
///
/// Guarantees mirror the Phase 5–9 workflow controllers:
/// * duplicate-submit is a no-op while submitting, or after a successful done
///   for the same request (a double tap never sends twice);
/// * a stale async result is dropped when a newer [SubmitReviewRequest]
///   superseded it — an edited rating/text is a *different* request, so a
///   genuine re-submit is allowed;
/// * on success the existing-review provider is invalidated and re-read; the
///   app never fabricates a review or assumes it is published.
class ReviewSubmissionController extends Notifier<ReviewActionState> {
  @override
  ReviewActionState build() => const ReviewIdle();

  Future<void> submit(String reservationId, ReviewDraft draft) async {
    final SubmitReviewRequest request =
        SubmitReviewRequest.fromDraft(reservationId, draft);
    final ReviewActionState current = state;
    if (current is ReviewSubmitting && current.request == request) return;
    if (current is ReviewSubmitDone &&
        current.request == request &&
        current.result.outcome.isSuccess) {
      return;
    }

    state = ReviewSubmitting(request);
    try {
      final ReviewContext ctx =
          await ref.read(reviewContextProvider(reservationId).future);
      final SubmitReviewResult result =
          await ref.read(reviewRepositoryProvider).submit(request, ctx);
      if (_superseded(request)) return;
      state = ReviewSubmitDone(request, result);
      if (result.outcome.isSuccess) {
        ref.invalidate(reservationReviewProvider(reservationId));
      }
    } catch (error) {
      if (_superseded(request)) return;
      state = ReviewSubmitFailed(request, ErrorMapper.toFailure(error));
    }
  }

  bool _superseded(SubmitReviewRequest request) {
    final ReviewActionState now = state;
    return now is ReviewSubmitting && now.request != request;
  }

  void reset() => state = const ReviewIdle();
}

final reviewSubmissionControllerProvider =
    NotifierProvider<ReviewSubmissionController, ReviewActionState>(
  ReviewSubmissionController.new,
);
