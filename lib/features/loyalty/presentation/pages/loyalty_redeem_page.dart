import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/loyalty_account.dart';
import '../../domain/entities/loyalty_operations.dart';
import '../loyalty_l10n.dart';
import '../state/loyalty_providers.dart';
import '../state/loyalty_redeem_controller.dart';
import '../widgets/loyalty_balance_card.dart';
import '../../../../core/widgets/app_icons.dart';

/// `14 · Entry, loyalty & completion` — choose how many points to redeem
/// against **this booking**. Not a rewards catalogue: the guest picks a points
/// amount, the backend records the ledger movement + a notional value; the
/// actual discount mechanism is a deferred backend integration.
class LoyaltyRedeemPage extends ConsumerStatefulWidget {
  const LoyaltyRedeemPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  ConsumerState<LoyaltyRedeemPage> createState() => _LoyaltyRedeemPageState();
}

class _LoyaltyRedeemPageState extends ConsumerState<LoyaltyRedeemPage> {
  static const int _step = 50;
  int? _points;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<LoyaltyAccount> accountAsync = ref.watch(
      loyaltyAccountProvider(widget.reservationId),
    );
    final AsyncValue<LoyaltyContext> ctxAsync = ref.watch(
      loyaltyContextProvider(widget.reservationId),
    );

    return Scaffold(
      appBar: HotelAppBar(title: l10n.loyaltyRedeemTitle),
      body: SafeArea(
        child: _merge(
          accountAsync,
          ctxAsync,
          loading: () =>
              Center(child: LoadingView(label: l10n.stateLoadingTitle)),
          error: (Object e) => MessageView(
            icon: AppIcons.loyalty,
            title: l10n.loyaltyUnavailableTitle,
            message: l10n.errorGeneric,
            actionLabel: l10n.commonBack,
            onAction: () => context.pop(),
          ),
          data: (LoyaltyAccount account, LoyaltyContext ctx) {
            if (!account.isActive ||
                !account.hasPoints ||
                !ctx.isRedeemableBooking) {
              return MessageView(
                icon: AppIcons.loyalty,
                title: l10n.loyaltyRedeemNotEligibleTitle,
                message: l10n.loyaltyRedeemNotEligibleBody,
                actionLabel: l10n.commonBack,
                onAction: () => context.pop(),
              );
            }
            return _Body(
              reservationId: widget.reservationId,
              account: account,
              currency: ctx.currency,
              points: _resolvedPoints(account.pointsBalance),
              onChanged: (int v) => setState(() => _points = v),
              step: _step,
            );
          },
        ),
      ),
    );
  }

  int _resolvedPoints(int balance) {
    final int fallback = balance < 100 ? balance : 100;
    final int p = _points ?? fallback;
    return p.clamp(_step.clamp(1, balance), balance);
  }

  static Widget _merge(
    AsyncValue<LoyaltyAccount> a,
    AsyncValue<LoyaltyContext> b, {
    required Widget Function() loading,
    required Widget Function(Object) error,
    required Widget Function(LoyaltyAccount, LoyaltyContext) data,
  }) {
    if (a.hasError) return error(a.error!);
    if (b.hasError) return error(b.error!);
    if (a.hasValue && b.hasValue) return data(a.requireValue, b.requireValue);
    return loading();
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.reservationId,
    required this.account,
    required this.currency,
    required this.points,
    required this.onChanged,
    required this.step,
  });

  final String reservationId;
  final LoyaltyAccount account;
  final String currency;
  final int points;
  final ValueChanged<int> onChanged;
  final int step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final RedeemActionState action = ref.watch(loyaltyRedeemControllerProvider);
    final bool forThis = action.requestOrNull?.reservationId == reservationId;
    final bool submitting = action is RedeemSubmitting && forThis;

    final RedeemPointsResult? result = action is RedeemDone && forThis
        ? action.result
        : null;

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            children: <Widget>[
              LoyaltyBalanceCard(account: account),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.loyaltyRedeemAmountLabel,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: <Widget>[
                        IconButton.outlined(
                          onPressed: (submitting || points - step < step)
                              ? null
                              : () => onChanged(points - step),
                          icon: const Icon(Icons.remove),
                          tooltip: l10n.stepperDecrease,
                        ),
                        Expanded(
                          child: Text(
                            l10n.loyaltyPointsValue(points),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        IconButton.outlined(
                          onPressed:
                              (submitting ||
                                  points + step > account.pointsBalance)
                              ? null
                              : () => onChanged(points + step),
                          icon: const Icon(Icons.add),
                          tooltip: l10n.stepperIncrease,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: submitting
                            ? null
                            : () => onChanged(account.pointsBalance),
                        child: Text(
                          l10n.loyaltyRedeemMax(account.pointsBalance),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.loyaltyRedeemNote, style: theme.textTheme.bodySmall),
              if (result != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                _RedeemResultBanner(result: result, currency: currency),
              ],
              if (action is RedeemFailed && forThis) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                InfoBanner(
                  tone: InfoBannerTone.error,
                  title: l10n.loyaltyUnavailableTitle,
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
          child: (result?.outcome == LoyaltyRedeemOutcome.redeemed)
              ? PrimaryButton(
                  label: l10n.commonBack,
                  onPressed: () => context.pop(),
                )
              : PrimaryButton(
                  label: submitting
                      ? l10n.loyaltyRedeemingCta
                      : l10n.loyaltyRedeemSubmitCta,
                  isLoading: submitting,
                  onPressed: submitting
                      ? null
                      : () => ref
                            .read(loyaltyRedeemControllerProvider.notifier)
                            .submit(reservationId, points),
                ),
        ),
      ],
    );
  }
}

class _RedeemResultBanner extends StatelessWidget {
  const _RedeemResultBanner({required this.result, required this.currency});

  final RedeemPointsResult result;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    if (result.outcome == LoyaltyRedeemOutcome.redeemed) {
      final int pts = result.transaction?.magnitude ?? 0;
      final String? value = result.transaction?.notionalValue;
      return InfoBanner(
        tone: InfoBannerTone.success,
        title: l10n.loyaltyRedeemedTitle,
        message: value == null
            ? l10n.loyaltyRedeemedBody(pts)
            : '${l10n.loyaltyRedeemedBody(pts)}\n${l10n.loyaltyRedeemedValueNote(currency, value)}',
      );
    }
    return InfoBanner(
      tone: result.outcome == LoyaltyRedeemOutcome.alreadyRedeemed
          ? InfoBannerTone.info
          : InfoBannerTone.warning,
      title: l10n.loyaltyRedeemOutcomeTitle(result.outcome),
      message: l10n.loyaltyRedeemOutcomeBody(result.outcome),
    );
  }
}
