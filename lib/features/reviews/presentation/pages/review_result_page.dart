import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/bottom_action_bar.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/result_view.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/submit_review.dart';
import '../state/review_submission_controller.dart';
import '../widgets/rating_selector.dart';

/// `05 · Depart & Invoice` — the authoritative review-submission outcome.
///
/// "Thank you / it's with our team" on success, a safe retry on an infra
/// failure, and a plain explanation for a blocked outcome (already reviewed /
/// not eligible). Never claims the review is published — moderation is the
/// backend's call.
class ReviewResultPage extends ConsumerWidget {
  const ReviewResultPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ReviewActionState action =
        ref.watch(reviewSubmissionControllerProvider);

    if (action is ReviewIdle || action is ReviewSubmitting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.pushReplacementNamed(
            AppRoutes.reviewFormName,
            pathParameters: <String, String>{'reservationId': reservationId},
          );
        }
      });
      return Scaffold(
        appBar: HotelAppBar(title: l10n.reviewResultTitle),
        body: Center(child: LoadingView(label: l10n.stateLoadingTitle)),
      );
    }

    return Scaffold(
      appBar: HotelAppBar(title: l10n.reviewResultTitle),
      body: SafeArea(
        child: _Body(reservationId: reservationId, action: action),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.reservationId, required this.action});

  final String reservationId;
  final ReviewActionState action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    final SubmitReviewResult? result = action.resultOrNull;
    final ReviewSubmitOutcome? outcome = result?.outcome;
    final Review? review = result?.review;

    final bool isFailure = action is ReviewSubmitFailed;
    final bool isBlocked = outcome != null && !outcome.isSuccess;
    final bool pendingModeration =
        review != null && review.status.isPending;

    final (InfoBannerTone tone, String title, String body) = switch (
        (isFailure, outcome)) {
      (true, _) => (
          InfoBannerTone.error,
          l10n.reviewFailedTitle,
          (action as ReviewSubmitFailed).failure.localizedMessage(l10n),
        ),
      (_, ReviewSubmitOutcome.alreadyReviewed) => (
          InfoBannerTone.info,
          l10n.reviewAlreadyTitle,
          l10n.reviewAlreadyBody,
        ),
      (_, ReviewSubmitOutcome.notEligible) => (
          InfoBannerTone.warning,
          l10n.reviewNotEligibleTitle,
          l10n.reviewNotEligibleBody,
        ),
      (_, ReviewSubmitOutcome.invalidRating) => (
          InfoBannerTone.warning,
          l10n.reviewInvalidRatingTitle,
          l10n.reviewInvalidRatingBody,
        ),
      _ => pendingModeration
          ? (
              InfoBannerTone.warning,
              l10n.reviewSubmittedTitle,
              l10n.reviewPendingModerationBody,
            )
          : (
              InfoBannerTone.success,
              l10n.reviewSubmittedTitle,
              l10n.reviewPublishedBody,
            ),
    };

    void toReservation() => context.goNamed(
          AppRoutes.reservationDetailName,
          pathParameters: <String, String>{'reservationId': reservationId},
        );

    void retry() {
      final SubmitReviewRequest? request = action.requestOrNull;
      if (request == null) {
        toReservation();
        return;
      }
      ref.read(reviewSubmissionControllerProvider.notifier).submit(
            reservationId,
            request.toDraft(),
          );
      context.pushReplacementNamed(
        AppRoutes.reviewProcessingName,
        pathParameters: <String, String>{'reservationId': reservationId},
      );
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: ResultView(
            tone: tone,
            title: title,
            message: body,
            detail: review != null && !isBlocked
                ? Center(child: RatingDisplay(rating: review.rating, size: 24))
                : null,
          ),
        ),
        BottomActionBar(
          children: <Widget>[
            if (isFailure) ...<Widget>[
              PrimaryButton(label: l10n.actionRetry, onPressed: retry),
              SecondaryButton(
                label: l10n.reviewBackToReservation,
                onPressed: toReservation,
              ),
            ] else
              PrimaryButton(
                label: l10n.reviewBackToReservation,
                onPressed: toReservation,
              ),
          ],
        ),
      ],
    );
  }
}
