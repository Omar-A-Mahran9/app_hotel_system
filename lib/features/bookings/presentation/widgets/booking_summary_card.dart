import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/numerals.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../reservation/domain/entities/reservation.dart';
import 'booking_status_pill.dart';

import '../../../../core/time/stay_date_format.dart';

/// The top hotel/dates/status/price block shared by every
/// `BOOKING_Detail_*.png` state.
class BookingSummaryCard extends StatelessWidget {
  const BookingSummaryCard({super.key, required this.reservation});

  final Reservation reservation;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Locale locale = Localizations.localeOf(context);
    final String dateRange = formatStayDateRange(locale, reservation.stay);

    // v2 `Data Card`: 64px thumbnail at the start, then title (15.5 bold),
    // the pin + "٢٨ — ٣٠ سبتمبر · ليلتان" line, and price … status pill.
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppImage.network(
            url: reservation.hotelImageUrl,
            width: 64,
            height: 64,
            borderRadius: AppRadius.allMd,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  reservation.hotelName.resolve(locale),
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 15.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: <Widget>[
                    Icon(
                      AppIcons.location,
                      size: 14,
                      color: context.colors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      child: Text(
                        '${context.localDigits(dateRange)}  ·  ${context.l10n.stayNights(reservation.stay.nights)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: context.colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: <Widget>[
                    MoneyText(
                      reservation.totalToPay.amount,
                      currency: reservation.totalToPay.currency,
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    BookingStatusPill(status: reservation.status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
