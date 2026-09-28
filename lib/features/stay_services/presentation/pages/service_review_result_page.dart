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
import '../../../reviews/presentation/widgets/rating_selector.dart';
import '../../domain/entities/service_review.dart';
import '../../domain/entities/submit_service_review.dart';
import '../state/service_review_submission_controller.dart';

/// The authoritative service-review-submission outcome. Mirrors
/// `ReviewResultPage`. Never claims the review is published — moderation is
/// the backend's call.
class ServiceReviewResultPage extends ConsumerWidget {
  const ServiceReviewResultPage({
    super.key,
    required this.reservationId,
    required this.serviceOrderId,
  });

  final String reservationId;
  final String serviceOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ServiceReviewActionState action =
        ref.watch(serviceReviewSubmissionControllerProvider);

    if (action is ServiceReviewIdle || action is ServiceReviewSubmitting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.pushReplacementNamed(
            AppRoutes.serviceReviewFormName,
            pathParameters: <String, String>{
              'reservationId': reservationId,
              'serviceOrderId': serviceOrderId,
            },
          );
        }
      });
      return Scaffold(
        appBar: HotelAppBar(title: l10n.serviceReviewResultTitle),
        body: Center(child: LoadingView(label: l10n.stateLoadingTitle)),
      );
    }

    return Scaffold(
      appBar: HotelAppBar(title: l10n.serviceReviewResultTitle),
      body: SafeArea(
        child: _Body(
          reservationId: reservationId,
          serviceOrderId: serviceOrderId,
          action: action,
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.reservationId,
    required this.serviceOrderId,
    required this.action,
  });

  final String reservationId;
  final String serviceOrderId;
  final ServiceReviewActionState action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    final SubmitServiceReviewResult? result = action.resultOrNull;
    final ServiceReviewSubmitOutcome? outcome = result?.outcome;
    final ServiceReview? review = result?.review;

    final bool isFailure = action is ServiceReviewSubmitFailed;
    final bool isBlocked = outcome != null && !outcome.isSuccess;
    final bool pendingModeration = review != null && review.status.isPending;

    final (InfoBannerTone tone, String title, String body) = switch (
        (isFailure, outcome)) {
      (true, _) => (
          InfoBannerTone.error,
          l10n.reviewFailedTitle,
          (action as ServiceReviewSubmitFailed).failure.localizedMessage(l10n),
        ),
      (_, ServiceReviewSubmitOutcome.alreadyReviewed) => (
          InfoBannerTone.info,
          l10n.reviewAlreadyTitle,
          l10n.reviewAlreadyBody,
        ),
      (_, ServiceReviewSubmitOutcome.notEligible) => (
          InfoBannerTone.warning,
          l10n.serviceReviewNotEligibleTitle,
          l10n.serviceReviewNotEligibleBody,
        ),
      (_, ServiceReviewSubmitOutcome.invalidRating) => (
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

    void toOrder() => context.goNamed(
          AppRoutes.serviceOrderDetailName,
          pathParameters: <String, String>{
            'reservationId': reservationId,
            'orderId': serviceOrderId,
          },
        );

    void retry() {
      final SubmitServiceReviewRequest? request = action.requestOrNull;
      if (request == null) {
        toOrder();
        return;
      }
      ref.read(serviceReviewSubmissionControllerProvider.notifier).submit(
            (reservationId: reservationId, orderId: serviceOrderId),
            request.toDraft(),
          );
      context.pushReplacementNamed(
        AppRoutes.serviceReviewProcessingName,
        pathParameters: <String, String>{
          'reservationId': reservationId,
          'serviceOrderId': serviceOrderId,
        },
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
                onPressed: toOrder,
              ),
            ] else
              PrimaryButton(
                label: l10n.reviewBackToReservation,
                onPressed: toOrder,
              ),
          ],
        ),
      ],
    );
  }
}
