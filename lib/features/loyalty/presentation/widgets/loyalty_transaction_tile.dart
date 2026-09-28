import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/loyalty_transaction.dart';
import '../../domain/entities/loyalty_transaction_type.dart';
import '../loyalty_l10n.dart';

/// One row in the points-history list (`14 · Entry, loyalty & completion`).
/// Earned points read green with a `+`, redeemed/removed read in the error
/// tone with a `−`. Every figure is the backend ledger delta, verbatim.
class LoyaltyTransactionTile extends StatelessWidget {
  const LoyaltyTransactionTile({
    super.key,
    required this.transaction,
    this.highlightReservationId,
  });

  final LoyaltyTransaction transaction;

  /// When this entry belongs to [highlightReservationId], a "this stay" chip is
  /// shown so the guest can find the row for the reservation they came from.
  final String? highlightReservationId;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final MaterialLocalizations ml = MaterialLocalizations.of(context);
    final AppSemanticColors semantic =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    final bool credit = transaction.isCredit;
    final Color amountColor = credit
        ? semantic.success
        : theme.colorScheme.error;
    final String amount = credit
        ? l10n.loyaltyPointsAdded(transaction.magnitude)
        : l10n.loyaltyPointsRemoved(transaction.magnitude);

    final bool isThisStay =
        highlightReservationId != null &&
        transaction.isForReservation(highlightReservationId!);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            transaction.type == LoyaltyTransactionType.earn
                ? IconsaxPlusLinear.add_circle
                : transaction.type == LoyaltyTransactionType.redeem
                ? IconsaxPlusLinear.minus_cirlce
                : IconsaxPlusLinear.arrow_swap_horizontal,
            size: 18,
            color: amountColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.loyaltyTransactionTypeLabel(transaction.type),
                  style: theme.textTheme.bodyLarge,
                ),
                if (transaction.createdAt != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    ml.formatMediumDate(transaction.createdAt!),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (isThisStay) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.loyaltyTxThisStay,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: semantic.accent,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            amount,
            style: theme.textTheme.titleSmall?.copyWith(
              color: amountColor,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
