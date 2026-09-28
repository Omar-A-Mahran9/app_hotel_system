import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../reviews/presentation/widgets/rating_selector.dart';
import '../../../reviews/presentation/widgets/review_status_pill.dart';
import '../../domain/entities/service_review.dart';
import '../../domain/entities/service_review_draft.dart';
import '../state/service_review_providers.dart';
import '../state/service_review_submission_controller.dart';
import '../state/stay_services_providers.dart' show ServiceOrderKey;

/// Rate a fulfilled service order — "كيف كانت الخدمة؟", the service-level
/// analogue of `ReviewFormPage`. If a review already exists it is shown
/// read-only. Eligibility (order must be `fulfilled`) is a UX pre-check; the
/// backend stays authoritative.
class ServiceReviewFormPage extends ConsumerStatefulWidget {
  const ServiceReviewFormPage({
    super.key,
    required this.reservationId,
    required this.serviceOrderId,
  });

  final String reservationId;
  final String serviceOrderId;

  ServiceOrderKey get _key =>
      (reservationId: reservationId, orderId: serviceOrderId);

  @override
  ConsumerState<ServiceReviewFormPage> createState() => _ServiceReviewFormPageState();
}

class _ServiceReviewFormPageState extends ConsumerState<ServiceReviewFormPage> {
  final TextEditingController _text = TextEditingController();
  ServiceReviewDraft _draft = const ServiceReviewDraft();
  bool _showRatingError = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ServiceOrderKey key = widget._key;
    final AsyncValue<ServiceReviewContext> ctxAsync =
        ref.watch(serviceReviewContextProvider(key));
    final AsyncValue<ServiceReview?> reviewAsync =
        ref.watch(serviceOrderReviewProvider(key));

    return Scaffold(
      appBar: HotelAppBar(title: l10n.serviceReviewFormTitle),
      body: SafeArea(
        child: _merge(
          ctxAsync,
          reviewAsync,
          loading: () => Center(child: LoadingView(label: l10n.stateLoadingTitle)),
          error: (Object e) => MessageView(
            icon: AppIcons.review,
            title: l10n.reviewUnavailableTitle,
            message: ErrorMapper.toFailure(e).localizedMessage(l10n),
            actionLabel: l10n.actionRetry,
            onAction: () {
              ref.invalidate(serviceReviewContextProvider(key));
              ref.invalidate(serviceOrderReviewProvider(key));
            },
          ),
          data: (ServiceReviewContext ctx, ServiceReview? review) {
            if (review != null) return _ExistingReview(review: review);
            if (!ctx.eligibility.canReview) {
              return MessageView(
                icon: AppIcons.review,
                title: l10n.serviceReviewNotEligibleTitle,
                message: l10n.serviceReviewNotEligibleBody,
                actionLabel: l10n.commonBack,
                onAction: () => context.pop(),
              );
            }
            return _Form(
              orderKey: key,
              draft: _draft,
              textController: _text,
              showRatingError: _showRatingError,
              onRating: (int r) => setState(() {
                _draft = _draft.copyWith(rating: r);
                _showRatingError = false;
              }),
              onText: (String t) => _draft = _draft.copyWith(text: t),
              onSubmit: () {
                if (!_draft.canSubmit) {
                  setState(() => _showRatingError = true);
                  return;
                }
                ref
                    .read(serviceReviewSubmissionControllerProvider.notifier)
                    .submit(key, _draft);
                context.pushNamed(
                  AppRoutes.serviceReviewProcessingName,
                  pathParameters: <String, String>{
                    'reservationId': key.reservationId,
                    'serviceOrderId': key.orderId,
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  static Widget _merge(
    AsyncValue<ServiceReviewContext> a,
    AsyncValue<ServiceReview?> b, {
    required Widget Function() loading,
    required Widget Function(Object) error,
    required Widget Function(ServiceReviewContext, ServiceReview?) data,
  }) {
    if (a.hasError) return error(a.error!);
    if (b.hasError) return error(b.error!);
    if (a.hasValue && b.hasValue) return data(a.requireValue, b.requireValue);
    return loading();
  }
}

class _Form extends ConsumerWidget {
  const _Form({
    required this.orderKey,
    required this.draft,
    required this.textController,
    required this.showRatingError,
    required this.onRating,
    required this.onText,
    required this.onSubmit,
  });

  final ServiceOrderKey orderKey;
  final ServiceReviewDraft draft;
  final TextEditingController textController;
  final bool showRatingError;
  final ValueChanged<int> onRating;
  final ValueChanged<String> onText;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final ServiceReviewActionState action =
        ref.watch(serviceReviewSubmissionControllerProvider);
    final bool submitting = action is ServiceReviewSubmitting &&
        action.request.serviceOrderId == orderKey.orderId;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            children: <Widget>[
              Text(l10n.serviceReviewFormPrompt, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  children: <Widget>[
                    RatingSelector(
                      rating: draft.rating,
                      onChanged: submitting ? null : onRating,
                    ),
                    if (showRatingError) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.reviewRatingRequired,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.reviewTextLabel,
                hintText: l10n.serviceReviewTextHint,
                controller: textController,
                enabled: !submitting,
                onChanged: onText,
                textInputAction: TextInputAction.newline,
              ),
              if (action is ServiceReviewSubmitFailed &&
                  action.request.serviceOrderId == orderKey.orderId) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                InfoBanner(
                  tone: InfoBannerTone.error,
                  title: l10n.reviewUnavailableTitle,
                  message: action.failure.localizedMessage(l10n),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.xs,
            AppSpacing.pageGutter,
            AppSpacing.md,
          ),
          child: PrimaryButton(
            label: submitting ? l10n.reviewSubmittingCta : l10n.reviewSubmitCta,
            isLoading: submitting,
            onPressed: submitting ? null : onSubmit,
          ),
        ),
      ],
    );
  }
}

class _ExistingReview extends StatelessWidget {
  const _ExistingReview({required this.review});

  final ServiceReview review;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final MaterialLocalizations ml = MaterialLocalizations.of(context);

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            children: <Widget>[
              InfoBanner(
                tone: review.status.isPublished
                    ? InfoBannerTone.success
                    : review.status.isRejected
                    ? InfoBannerTone.error
                    : InfoBannerTone.info,
                title: review.status.isRejected
                    ? l10n.reviewRejectedTitle
                    : l10n.reviewAlreadyTitle,
                message: review.status.isRejected
                    ? l10n.reviewRejectedBody
                    : review.status.isPublished
                    ? l10n.reviewPublishedBody
                    : l10n.reviewPendingModerationBody,
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            l10n.reviewYourRatingLabel,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        ReviewStatusPill(status: review.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    RatingDisplay(rating: review.rating, size: 24),
                    if (review.hasText) ...<Widget>[
                      const Divider(height: AppSpacing.lg),
                      Text(review.text!, style: theme.textTheme.bodyMedium),
                    ],
                    if (review.createdAt != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        ml.formatMediumDate(review.createdAt!),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.xs,
            AppSpacing.pageGutter,
            AppSpacing.md,
          ),
          child: SecondaryButton(
            label: l10n.reviewBackToReservation,
            onPressed: () => context.pop(),
          ),
        ),
      ],
    );
  }
}
