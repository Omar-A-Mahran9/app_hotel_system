import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/bottom_action_bar.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/result_view.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/state/reservation_detail_provider.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/entities/payment_result.dart';
import '../payment_l10n.dart';
import '../state/payment_controller.dart';
import '../widgets/payment_status_pill.dart';
import '../widgets/payment_summary_card.dart';
import '../../../discovery/domain/entities/money.dart';

/// `03 · Pay & Verify` — the authoritative outcome of the hold request.
///
/// Renders exactly what the repository resolved: a held deposit, a still-pending
/// hold, or a safe failure with a retry action. It never claims success before
/// the repository confirms it, and it never changes the reservation status.
class PaymentResultPage extends ConsumerWidget {
  const PaymentResultPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final PaymentActionState action = ref.watch(paymentControllerProvider);

    // Reached without a resolved action (deep link / reload) — back to review.
    if (action is PaymentActionIdle || action is PaymentActionSubmitting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.pushReplacementNamed(
            AppRoutes.paymentReviewName,
            pathParameters: <String, String>{'reservationId': reservationId},
          );
        }
      });
      return Scaffold(
        appBar: HotelAppBar(title: l10n.paymentResultTitle),
        body: Center(child: LoadingView(label: l10n.stateLoadingTitle)),
      );
    }

    final AsyncValue<Reservation> reservationAsync =
        ref.watch(reservationDetailProvider(reservationId));

    return Scaffold(
      appBar: HotelAppBar(title: l10n.paymentResultTitle),
      body: SafeArea(
        child: reservationAsync.maybeWhen(
          data: (Reservation reservation) => _Body(
            reservation: reservation,
            action: action,
          ),
          orElse: () => Center(child: LoadingView(label: l10n.stateLoadingTitle)),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.reservation, required this.action});

  final Reservation reservation;
  final PaymentActionState action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final PaymentHoldRequest request =
        PaymentHoldRequest.forReservation(reservation);

    final PaymentResult? result = action.resultOrNull;
    final bool isFailure =
        action is PaymentActionFailed || (result?.outcome.isRetryable ?? false);
    final bool isPending = result?.outcome == PaymentOutcome.pending;
    final bool isSuccess = result?.outcome.isSuccess ?? false;

    final String title = switch (action) {
      PaymentActionFailed() => l10n.paymentFailedTitle,
      PaymentActionDone(:final PaymentResult result) =>
        l10n.paymentOutcomeTitle(result.outcome),
      _ => l10n.paymentResultTitle,
    };
    final String body = switch (action) {
      PaymentActionFailed(:final failure) => failure.localizedMessage(l10n),
      PaymentActionDone(:final PaymentResult result) =>
        l10n.paymentOutcomeBody(result.outcome),
      _ => '',
    };

    final InfoBannerTone tone = ResultView.toneFor(
      success: isSuccess,
      pending: isPending,
      error: isFailure,
    );

    final Payment payment = result?.payment ??
        Payment.none(
          reservationId: reservation.id,
          hotelId: reservation.hotelId,
          amount: reservation.depositAmount ??
              Money(amount: 0, currency: reservation.priceSnapshot.currency),
        );

    return Column(
      children: <Widget>[
        Expanded(
          child: ResultView(
            tone: tone,
            title: title,
            message: body.isEmpty ? null : body,
            detail: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (result != null) ...<Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          l10n.paymentStatusFieldLabel,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      PaymentStatusPill(status: result.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                PaymentSummaryCard(reservation: reservation, payment: payment),
              ],
            ),
          ),
        ),
        BottomActionBar(
          children: <Widget>[
            if (isFailure)
              PrimaryButton(
                label: l10n.paymentRetryCta,
                onPressed: () {
                  ref.read(paymentControllerProvider.notifier).submit(request);
                  context.pushReplacementNamed(
                    AppRoutes.paymentProcessingName,
                    pathParameters: <String, String>{
                      'reservationId': reservation.id,
                    },
                  );
                },
              ),
            if (isSuccess)
              PrimaryButton(
                label: l10n.identityVerifyCta,
                onPressed: () => context.pushNamed(
                  AppRoutes.identityVerificationName,
                  pathParameters: <String, String>{
                    'reservationId': reservation.id,
                  },
                ),
              ),
            (isSuccess || isFailure)
                ? SecondaryButton(
                    label: l10n.paymentBackToReservation,
                    onPressed: () => _toReservation(context, reservation.id),
                  )
                : PrimaryButton(
                    label: l10n.paymentBackToReservation,
                    onPressed: () => _toReservation(context, reservation.id),
                  ),
          ],
        ),
      ],
    );
  }

  void _toReservation(BuildContext context, String id) {
    context.goNamed(
      AppRoutes.reservationDetailName,
      pathParameters: <String, String>{'reservationId': id},
    );
  }
}
