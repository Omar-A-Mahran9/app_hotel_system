import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../discovery/presentation/widgets/guest_party_sheet.dart'
    show guestPartySummaryText;
import '../../domain/entities/reservation.dart';

/// The hotel / room / dates / guests / price recap for a [Reservation], used on
/// the confirmation and details screen. Mirrors the discovery review card's
/// layout so the guest sees the same shape before and after confirming.
class ReservationSummaryCard extends StatelessWidget {
  const ReservationSummaryCard({super.key, required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final MaterialLocalizations ml = MaterialLocalizations.of(context);
    final Locale locale = Localizations.localeOf(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Row(
            label: l10n.reviewHotelLabel,
            value: reservation.hotelName.resolve(locale),
          ),
          const Divider(height: AppSpacing.lg),
          _Row(
            label: l10n.reviewRoomLabel,
            value: reservation.roomName.resolve(locale),
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
          const SizedBox(height: AppSpacing.xs),
          _Row(
            label: l10n.reviewStayLabel,
            value: l10n.stayNights(reservation.nights),
          ),
          const Divider(height: AppSpacing.lg),
          _Row(
            label: l10n.reviewGuestsLabel,
            value: guestPartySummaryText(l10n, reservation.party),
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.reviewTotalLabel(reservation.nights),
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                l10n.priceStayTotal(MoneyText.digits(context, reservation.priceSnapshot.amount)),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.extension<AppSemanticColors>()?.accent ??
                      AppColors.bronze500,
                ),
              ),
            ],
          ),
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
        Expanded(
          child: Text(value, style: theme.textTheme.bodyLarge),
        ),
      ],
    );
  }
}
