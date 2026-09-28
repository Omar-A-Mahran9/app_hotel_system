import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/folio.dart';
import '../checkout_l10n.dart';

/// `05 · Depart & Invoice` screen 1 — the "ملخص الفاتورة" card: one row per
/// posted charge, then the backend total. Every figure is displayed as-is; the
/// app never sums anything.
class FolioSummaryCard extends StatelessWidget {
  const FolioSummaryCard({super.key, required this.folio, this.showOutstanding = true});

  final Folio folio;
  final bool showOutstanding;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final AppSemanticColors semantic =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.folioSummaryTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final FolioCharge charge in folio.postedCharges) ...<Widget>[
            _line(
              theme,
              label: charge.quantity > 1
                  ? '${l10n.folioChargeLabel(charge)} ×${charge.quantity}'
                  : l10n.folioChargeLabel(charge),
              value: l10n.moneyAmount(
                  charge.totalAmount.currency, MoneyText.digits(context, charge.totalAmount.amount)),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          const Divider(height: AppSpacing.lg),
          _line(
            theme,
            label: l10n.folioTotalLabel,
            value: l10n.moneyAmount(
                folio.chargesTotal.currency, MoneyText.digits(context, folio.chargesTotal.amount)),
            emphasise: true,
          ),
          if (folio.paymentsTotal.amount > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            _line(
              theme,
              label: l10n.folioPaidLabel,
              value: '−${l10n.moneyAmount(folio.paymentsTotal.currency, MoneyText.digits(context, folio.paymentsTotal.amount))}',
            ),
          ],
          if (showOutstanding) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            _line(
              theme,
              label: l10n.folioOutstandingLabel,
              value: l10n.moneyAmount(folio.outstandingTotal.currency,
                  MoneyText.digits(context, folio.outstandingTotal.amount)),
              emphasise: true,
              color: semantic.accent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _line(
    ThemeData theme, {
    required String label,
    required String value,
    bool emphasise = false,
    Color? color,
  }) {
    final TextStyle? style = emphasise
        ? theme.textTheme.titleSmall
        : theme.textTheme.bodyMedium;
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: style)),
        Text(
          value,
          style: style?.copyWith(color: color ?? AppColors.ink900),
        ),
      ],
    );
  }
}
