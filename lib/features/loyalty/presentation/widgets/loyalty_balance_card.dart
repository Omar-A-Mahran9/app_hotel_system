import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../domain/entities/loyalty_account.dart';

/// The brown points-balance card (`14 · Entry, loyalty & completion`). Shows the
/// **backend** balance and the group-wide copy — no tier, no rate, no
/// conversion (none exist in the MVP). Built on the `Card` component's
/// `inverse` style.
class LoyaltyBalanceCard extends StatelessWidget {
  const LoyaltyBalanceCard({super.key, required this.account});

  final LoyaltyAccount account;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final AppColorTokens c = context.colors;

    return AppCard(
      style: AppCardStyle.inverse,
      padding: const EdgeInsets.all(AppSpacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.loyaltyBalanceLabel,
            style: theme.textTheme.bodySmall?.copyWith(color: c.accentWarm),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            l10n.loyaltyPointsValue(account.pointsBalance),
            style: theme.textTheme.displaySmall?.copyWith(
              color: c.textOnInverse,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(AppIcons.guests, size: 15, color: c.accentWarm),
              const SizedBox(width: AppSpacing.space1),
              Expanded(
                child: Text(
                  l10n.loyaltyGroupWideNote,
                  style: theme.textTheme.bodySmall?.copyWith(color: c.accentWarm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
