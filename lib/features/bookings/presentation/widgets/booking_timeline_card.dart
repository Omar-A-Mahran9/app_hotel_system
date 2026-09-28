import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/money_text.dart';

/// One row of a [BookingTimelineCard].
class BookingTimelineRow {
  const BookingTimelineRow({
    required this.title,
    this.subtitle,
    this.amount,
    this.currency,
    this.filled = false,
  });

  final String title;
  final String? subtitle;

  /// A money value shown under the title (17 bold, riyal mark) — e.g. the
  /// deposit held or the extra charges.
  final num? amount;
  final String? currency;

  /// A filled dot marks the row the guest's booking is currently "at" — the
  /// step already reached or in progress. Later rows show a hollow dot.
  final bool filled;
}

/// The "حالة الدفع" vertical stepper on the booking-detail screen (all six
/// `BOOKING_Detail_*` boards): a heading, then up to three dot-and-text rows.
/// The dot column is pinned LTR regardless of the app's reading direction —
/// Figma keeps the timeline's chronological axis fixed the same way a date
/// axis would be, independent of text direction.
class BookingTimelineCard extends StatelessWidget {
  const BookingTimelineCard({super.key, required this.rows});

  final List<BookingTimelineRow> rows;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final AppColorTokens c = context.colors;

    // v2 `BOOKING_Detail_*`: 18px padding, 18 bold heading, rows 10px
    // apart; an 8px dot (current = text primary, later = border) 10px from
    // 14 Regular title + 12 Regular subtitle. No connector lines.
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(l10n.bookingPaymentStatusHeading, style: theme.textTheme.titleLarge),
          for (final BookingTimelineRow row in rows) ...<Widget>[
            const SizedBox(height: 10),
            Row(
              textDirection: TextDirection.ltr,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: row.filled ? c.textPrimary : c.borderDefault,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        row.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 24 / 14,
                          fontWeight: FontWeight.w400,
                          color: row.filled ? c.textPrimary : c.textSecondary,
                        ),
                      ),
                      if (row.subtitle != null)
                        Text(
                          row.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            height: 18 / 12,
                            color: c.textSecondary,
                          ),
                        ),
                      if (row.amount != null)
                        MoneyText(
                          row.amount!,
                          currency: row.currency,
                          style: theme.textTheme.titleMedium,
                          color: c.textPrimary,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
