import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/bottom_action_bar.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/result_view.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../domain/entities/checkout.dart';
import '../state/checkout_controller.dart';

/// `05 · Depart & Invoice` screen 3 — the authoritative checkout outcome:
/// "thank you for your stay" on success, a safe retry on settlement failure, a
/// waiting state while pending. Never claims completion before the repository
/// confirms it.
class CheckoutCompletionPage extends ConsumerWidget {
  const CheckoutCompletionPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final CheckoutActionState action = ref.watch(checkoutControllerProvider);

    if (action is CheckoutIdle || action is CheckoutSubmitting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.pushReplacementNamed(
            AppRoutes.checkoutName,
            pathParameters: <String, String>{'reservationId': reservationId},
          );
        }
      });
      return Scaffold(
        appBar: HotelAppBar(title: l10n.checkoutCompleteTitle),
        body: Center(child: LoadingView(label: l10n.stateLoadingTitle)),
      );
    }

    return Scaffold(
      appBar: HotelAppBar(title: l10n.checkoutCompleteTitle),
      body: SafeArea(child: _Body(reservationId: reservationId, action: action)),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.reservationId, required this.action});

  final String reservationId;
  final CheckoutActionState action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);

    final CheckoutResult? result = action.resultOrNull;
    final bool isFailure = action is CheckoutFailed ||
        (result?.outcome == CheckoutOutcome.settlementFailed);
    final bool isPending =
        result?.outcome == CheckoutOutcome.settlementPending;
    final bool isSuccess = result?.outcome.isSuccess ?? false;

    final (InfoBannerTone tone, String title, String body) = isSuccess
        ? (
            InfoBannerTone.success,
            l10n.checkoutDoneTitle,
            l10n.checkoutDoneBody,
          )
        : isPending
            ? (
                InfoBannerTone.warning,
                l10n.checkoutPendingTitle,
                l10n.checkoutPendingBody,
              )
            : (
                InfoBannerTone.error,
                l10n.checkoutFailedTitle,
                action is CheckoutFailed
                    ? (action as CheckoutFailed).failure.localizedMessage(l10n)
                    : l10n.checkoutFailedBody,
              );

    void done() => context.goNamed(
          AppRoutes.reservationDetailName,
          pathParameters: <String, String>{'reservationId': reservationId},
        );

    void retry() {
      ref.read(checkoutControllerProvider.notifier).submit(reservationId);
      context.pushReplacementNamed(
        AppRoutes.checkoutProcessingName,
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
            detail: result != null && result.checkout.chargesTotal.amount > 0
                ? AppCard(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(l10n.invoiceTitle,
                              style: theme.textTheme.titleSmall),
                        ),
                        MoneyText(result.checkout.chargesTotal.amount, currency: result.checkout.chargesTotal.currency),
                      ],
                    ),
                  )
                : null,
          ),
        ),
        BottomActionBar(
          children: <Widget>[
            if (isFailure)
              PrimaryButton(label: l10n.checkoutRetryCta, onPressed: retry),
            if (isSuccess)
              PrimaryButton(
                label: l10n.checkoutViewInvoiceCta,
                onPressed: () => context.pushNamed(
                  AppRoutes.invoiceName,
                  pathParameters: <String, String>{
                    'reservationId': reservationId,
                  },
                ),
              ),
            (isSuccess)
                ? SecondaryButton(label: l10n.checkoutDoneCta, onPressed: done)
                : PrimaryButton(label: l10n.checkoutDoneCta, onPressed: done),
          ],
        ),
      ],
    );
  }
}
