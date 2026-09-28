import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/service_order.dart';
import 'service_order_status_pill.dart';

/// A row in the "my requests" list (`11 · Services & requests` screen 3).
class ServiceOrderCard extends StatelessWidget {
  const ServiceOrderCard({super.key, required this.order, required this.onTap});

  final ServiceOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final Locale locale = Localizations.localeOf(context);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  order.quantity > 1
                      ? '${order.serviceName.resolve(locale)} ×${order.quantity}'
                      : order.serviceName.resolve(locale),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(order.reference, style: theme.textTheme.bodySmall),
                if (order.totalAmount.amount > 0) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    l10n.moneyAmount(
                        order.totalAmount.currency, MoneyText.digits(context, order.totalAmount.amount)),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ServiceOrderStatusPill(status: order.status),
        ],
      ),
    );
  }
}
