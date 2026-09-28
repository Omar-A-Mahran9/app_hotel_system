import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../domain/entities/payment.dart';
import 'payment_status_pill.dart';
import '../../../discovery/domain/entities/money.dart';

/// The reservation reference / hotel / stay dates / amount / payment-status
/// recap shown on the payment review and result screens. Amount and currency
/// come from the authoritative [Reservation] price snapshot (mirrored by
/// [payment]); nothing is shown that the backend has not confirmed.
class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({
    super.key,
    required this.reservation,
    required this.payment,
  });

  final Reservation reservation;
  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final MaterialLocalizations ml = MaterialLocalizations.of(context);
    final Locale locale = Localizations.localeOf(context);
    // The deposit hold — the placed hold's amount, else what the server says
    // it will be (`hotel.deposit_amount`); never the stay total.
    final Money? deposit = payment.exists && payment.amount.amount > 0
        ? payment.amount
        : reservation.depositAmount;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Row(
            label: l10n.paymentReservationLabel,
            value: reservation.reference,
          ),
          const Divider(height: AppSpacing.lg),
          _Row(
            label: l10n.reviewHotelLabel,
            value: reservation.hotelName.resolve(locale),
          ),
          const Divider(height: AppSpacing.lg),
          _Row(
            label: l10n.reviewCheckInLabel,
            value: ml.formatFullDate(reservation.stay.checkIn),
          ),
          const SizedBox(height: AppSpacing.xs),
          _Row(
            label: l10n.reviewCheckOutLabel,
            value: ml.formatFullDate(reservation.stay.checkOut),
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.paymentStatusFieldLabel,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              PaymentStatusPill(status: payment.status),
            ],
          ),
          if (deposit != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    l10n.paymentCardDepositLabel,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                MoneyText(
                  deposit.amount,
                  currency: deposit.currency,
                  style: theme.textTheme.titleMedium,
                  color: context.colors.textPrimary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 110,
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
      ],
    );
  }
}
