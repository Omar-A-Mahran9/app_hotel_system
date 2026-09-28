import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../domain/entities/identity_verification_session.dart';
import '../state/identity_verification_controller.dart';
import '../widgets/verification_result_view.dart';
import '../../../../core/widgets/app_icons.dart';

/// `10 · Identity verification` — the authoritative outcome screen.
///
/// Reads the same per-reservation controller as the flow page and renders only
/// what the repository resolved: verified, awaiting manual review, or (reachable
/// from the reservation screen) a retryable / rejected state. It never claims
/// approval on its own.
class IdentityVerificationResultPage extends ConsumerWidget {
  const IdentityVerificationResultPage({
    super.key,
    required this.reservationId,
  });

  final String reservationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final IdentityVerificationState state = ref.watch(
      identityVerificationControllerProvider(reservationId),
    );
    final IdentityVerificationSession? session = state.session;

    if (session == null || state.isBusy) {
      return Scaffold(
        appBar: HotelAppBar(title: l10n.identityVerificationResultTitle),
        body: Center(child: LoadingView(label: l10n.stateLoadingTitle)),
      );
    }

    // Not a resolved state (e.g. deep-linked mid-flow) — send back to the flow.
    if (!session.isApproved && !session.isManualReview && !session.canRetry) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.pushReplacementNamed(
            AppRoutes.identityVerificationName,
            pathParameters: <String, String>{'reservationId': reservationId},
          );
        }
      });
      return Scaffold(
        appBar: HotelAppBar(title: l10n.identityVerificationResultTitle),
        body: Center(child: LoadingView(label: l10n.stateLoadingTitle)),
      );
    }

    final bool canRetry = session.canRetry && !session.isApproved;

    return Scaffold(
      appBar: HotelAppBar(title: l10n.identityVerificationResultTitle),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(child: VerificationResultView(session: session)),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.pageGutter,
                AppSpacing.xs,
                AppSpacing.pageGutter,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (canRetry) ...<Widget>[
                    PrimaryButton(
                      label: l10n.identityRetryCta,
                      onPressed: () => context.pushReplacementNamed(
                        AppRoutes.identityVerificationName,
                        pathParameters: <String, String>{
                          'reservationId': reservationId,
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  if (session.isManualReview) ...<Widget>[
                    SecondaryButton(
                      label: l10n.actionCheckAgain,
                      icon: AppIcons.refresh,
                      onPressed: () => ref
                          .read(
                            identityVerificationControllerProvider(
                              reservationId,
                            ).notifier,
                          )
                          .refresh(),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  if (session.isApproved) ...<Widget>[
                    PrimaryButton(
                      label: l10n.identityGoToCheckInCta,
                      onPressed: () => context.goNamed(
                        AppRoutes.checkInName,
                        pathParameters: <String, String>{
                          'reservationId': reservationId,
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  canRetry || session.isApproved
                      ? SecondaryButton(
                          label: l10n.identityBackToReservation,
                          onPressed: () => _toReservation(context),
                        )
                      : PrimaryButton(
                          label: l10n.identityBackToReservation,
                          onPressed: () => _toReservation(context),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toReservation(BuildContext context) {
    context.goNamed(
      AppRoutes.reservationDetailName,
      pathParameters: <String, String>{'reservationId': reservationId},
    );
  }
}
