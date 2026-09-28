import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';

import '../../../../core/localization/numerals.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/stay_date_format.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../reservation/domain/entities/reservation.dart';
import 'booking_status_pill.dart';

/// One row in the Bookings list (`BOOKINGS_List_Current.png` /
/// `BOOKINGS_List_Past.png`): hotel name, dates, a coarse status pill, the
/// price and a thumbnail.
class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.reservation, this.onTap});

  final Reservation reservation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Locale locale = Localizations.localeOf(context);
    final String dateRange = formatStayDateRange(locale, reservation.stay);

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // v2: the thumbnail leads (right in Arabic).
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
                // `BOOKINGS_List_*`: "فندق الواحة · غرفة 412" once a room is
                // assigned (front desk), then pin · dates · nights.
                Text(
                  reservation.roomNumber == null
                      ? reservation.hotelName.resolve(locale)
                      : '${reservation.hotelName.resolve(locale)} · ${context.l10n.bookingRoomNumber(reservation.roomNumber!)}',
                  style: theme.textTheme.titleSmall,
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
                    Flexible(
                      child: Text(
                        '${context.localDigits(dateRange)} · ${context.l10n.stayNights(reservation.nights)}',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // price at the start, status pill at the end.
                Row(
                  children: <Widget>[
                    MoneyText(reservation.totalToPay.amount, currency: reservation.totalToPay.currency),
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
