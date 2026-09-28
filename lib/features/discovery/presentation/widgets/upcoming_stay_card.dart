import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/money_text.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/upcoming_stay.dart';
import 'hotel_thumbnail.dart';

/// The `إقامتك القادمة` card on Home — laid out on the v2 Figma `Frame 38`
/// stay card (`02 · Discover & Book`):
///
/// * white, radius 14, 0.5px `border/default`, soft shadow; 16px padding and a
///   16px rhythm;
/// * a 48×48 photo thumbnail (radius 8) beside the room name and hotel/city;
/// * the available status and nightly rate share a compact second row.
///
/// `Frame 38` also shows check-in/out dates; [UpcomingStay] carries no dates
/// (nor a photo) in its response; real hotel cover imagery and a dummy-only
/// Figma fixture image fill the thumbnail when available. Tapping the card
/// opens the booking.
class UpcomingStayCard extends StatelessWidget {
  const UpcomingStayCard({super.key, required this.stay, required this.onTap});

  final UpcomingStay stay;
  final VoidCallback onTap;

  static const double _radius = 14;

  /// Figma `next stay` shadow: the tile pair, dropped 1px.
  static const List<BoxShadow> _shadow = <BoxShadow>[
    BoxShadow(color: Color(0x0A101517), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0F101517), offset: Offset(0, 1), blurRadius: 3),
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;
    final Locale locale = Localizations.localeOf(context);
    final AppColorTokens c = context.colors;

    return Material(
      color: c.bgSurface,
      borderRadius: const BorderRadius.all(Radius.circular(_radius)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(_radius)),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space3),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(_radius)),
            border: Border.all(color: c.borderDefault, width: 0.5),
            boxShadow: _shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  HotelThumbnail(
                    imageUrl: stay.imageUrl,
                    seed: stay.imageSeed,
                    width: 48,
                    height: 48,
                    borderRadius: AppRadius.allSm,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          stay.roomName.resolve(locale),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: c.textPrimary,
                            fontWeight: AppTypography.medium,
                            height: 18 / 14,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space1),
                        Row(
                          children: <Widget>[
                            Icon(
                              AppIcons.location,
                              size: 14,
                              color: c.textAccent,
                            ),
                            const SizedBox(width: AppSpacing.space1),
                            Flexible(
                              child: Text(
                                '${stay.hotelName.resolve(locale)} — '
                                '${stay.cityName.resolve(locale)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.bodySmall?.copyWith(
                                  color: c.textAccent,
                                  height: 16 / 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Row(
                children: <Widget>[
                  MoneyText(
                    stay.nightlyRate.amount,
                    currency: stay.nightlyRate.currency,
                    suffix: l10n.roomCardPerNight,
                    style: AppTypography.numMd(c.textPrimary, size: 16),
                  ),
                  const Spacer(),
                  StatusPill(
                    label: stay.isAvailable
                        ? l10n.hotelAvailable
                        : l10n.reservationStatusCancelled,
                    foreground: stay.isAvailable ? c.successFg : c.errorFg,
                    background: stay.isAvailable ? c.successBg : c.errorBg,
                    icon: stay.isAvailable
                        ? AppIcons.shieldCheck
                        : AppIcons.close,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
