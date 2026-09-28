import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/money_text.dart';
import '../../domain/entities/available_room.dart';
import '../discovery_l10n.dart';
import 'hotel_thumbnail.dart';
import '../../../../core/widgets/app_icons.dart';

/// Figma `Available Room Card` (`16 · Stay dates & available rooms` →
/// `ROOMS_Available`, component `room card / State=Default`): a white 20px
/// card with a soft two-layer shadow, 16 padding, 12 between its rows —
///
/// 1. **top** — the 88×88 photo (radius 20) and, 14 beside it, the name
///    (15.5 Bold), description (13 Regular, ≤ 2 lines), the capacity · bed
///    line and the amenities line, 6 apart;
/// 2. **badges** — "متاحة" (green) and "إلغاء مجاني" (blue), 20 tall pills
///    with the filled shield-tick;
/// 3. a 1px hairline;
/// 4. **bottom** — the nightly price (17 Bold + riyal mark, "/ الليلة"
///    under it) and the component's "price total" slot (14 Medium + riyal
///    mark, "الإجمالي لليلتين") at the start, the 40px outlined
///    "عرض التفاصيل" at the end.
///
/// Colours come from [RoomCardPalette] (the v2 palette).
///
/// Selection happens on the room-detail screen, not here — a selected room is
/// outlined in the primary colour and carries a "Selected" pill. Sold-out
/// rooms are dimmed, carry a red "not available" pill and disable the action.
class RoomSummaryCard extends StatelessWidget {
  const RoomSummaryCard({
    super.key,
    required this.room,
    required this.nights,
    required this.selected,
    required this.onViewDetails,
    this.showStayTotal = true,
  });

  final AvailableRoom room;
  final int nights;
  final bool selected;
  final VoidCallback onViewDetails;

  /// Whether to show the stay total under the nightly rate. Off on the
  /// single-hotel Home list where no dates are chosen yet.
  final bool showStayTotal;

  static const List<BoxShadow> _shadow = <BoxShadow>[
    BoxShadow(color: Color(0x0A101517), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0F101517), offset: Offset(0, 1), blurRadius: 3),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;
    final Locale locale = Localizations.localeOf(context);
    final AppColorTokens colors = context.colors;
    final RoomCardPalette palette = RoomCardPalette.of(context);
    final bool soldOut = !room.isAvailable;
    final BorderRadius radius = BorderRadius.circular(20);

    final List<String> specs = <String>[
      l10n.roomOccupancy(room.roomType.maxOccupancy),
      room.roomType.bedType.resolve(locale),
    ].where((String s) => s.trim().isNotEmpty).toList();
    final List<String> amenities = <String>[
      for (final amenity in room.roomType.amenities)
        l10n.roomAmenityLabel(amenity),
      if (room.roomType.breakfastIncluded) l10n.amenityBreakfast,
    ];
    final String description = room.roomType.description.resolve(locale);

    final TextStyle secondary = AppTypography.labelRegular(
      palette.muted,
    ).copyWith(height: 16 / 13);

    return Opacity(
      opacity: soldOut ? 0.6 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: radius,
          boxShadow: _shadow,
          border: selected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: soldOut ? null : onViewDetails,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      HotelThumbnail(
                        imageUrl: room.roomType.coverUrl,
                        width: 88,
                        height: 88,
                        borderRadius: radius,
                        icon: AppIcons.bed,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Flexible(
                                  child: Text(
                                    room.roomType.name.resolve(locale),
                                    style: AppTypography.bodyStrong(palette.ink)
                                        .copyWith(
                                          fontSize: 15.5,
                                          height: 19 / 15.5,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (selected) ...<Widget>[
                                  const SizedBox(width: 8),
                                  _Pill(
                                    label: l10n.roomSelected,
                                    foreground: theme.colorScheme.onPrimary,
                                    background: theme.colorScheme.primary,
                                    icon: AppIcons.check,
                                    iconColor: theme.colorScheme.onPrimary,
                                  ),
                                ],
                              ],
                            ),
                            if (description.trim().isNotEmpty) ...<Widget>[
                              const SizedBox(height: 6),
                              Text(
                                description,
                                style: secondary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (specs.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 6),
                              // Figma `specs`: capacity · bed, 6 apart.
                              Text(
                                specs.join('\u2002·\u2002'),
                                style: secondary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (amenities.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 6),
                              Text(
                                amenities.join(' · '),
                                style: secondary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: <Widget>[
                      if (soldOut)
                        _Pill(
                          label: l10n.roomSoldOut,
                          foreground: colors.errorFg,
                          background: colors.errorBg,
                          icon: AppIcons.close,
                          iconColor: colors.errorFg,
                        )
                      else
                        _Pill(
                          label: l10n.hotelAvailable,
                          foreground: palette.availableFg,
                          background: palette.availableBg,
                          icon: AppIcons.shieldCheck,
                          iconColor: palette.badgeIcon,
                        ),
                      if (room.roomType.refundable)
                        _Pill(
                          label: l10n.roomCardFreeCancellation,
                          foreground: palette.cancellationFg,
                          background: palette.cancellationBg,
                          icon: AppIcons.shieldCheck,
                          iconColor: palette.badgeIcon,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, thickness: 1, color: palette.hairline),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      // Prices lead (the start edge — right in Arabic), the
                      // action sits opposite.
                      Expanded(
                        child: _Prices(
                          room: room,
                          nights: nights,
                          showStayTotal: showStayTotal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: soldOut ? null : onViewDetails,
                        style: _ctaStyle(palette),
                        child: Text(
                          soldOut ? l10n.roomSoldOut : l10n.roomViewDetails,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Figma `cta`: 40 tall, content-sized pill, 1.5px `#D3E5E8` outline,
  /// 16 side padding, 14 Bold `#123F46` label.
  static ButtonStyle _ctaStyle(RoomCardPalette palette) =>
      OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        fixedSize: const Size.fromHeight(40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        foregroundColor: palette.ctaText,
        backgroundColor: palette.surface,
        side: BorderSide(color: palette.ctaBorder, width: 1.5),
        shape: const StadiumBorder(),
        textStyle: AppTypography.bodySmStrong(
          palette.ctaText,
        ).copyWith(height: 17 / 14),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
}

/// Figma `prices`: `price per night` (riyal mark + 17 Bold amount, then
/// "/ الليلة" 12 Regular 2 below) and, 4 under it, `price total` (riyal mark
/// + 14 Medium amount beside "الإجمالي لليلتين"). Both amounts use the drawn
/// [RiyalMark] — never a `﷼` text glyph.
class _Prices extends StatelessWidget {
  const _Prices({
    required this.room,
    required this.nights,
    required this.showStayTotal,
  });

  final AvailableRoom room;
  final int nights;
  final bool showStayTotal;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final RoomCardPalette palette = RoomCardPalette.of(context);
    final TextStyle caption = AppTypography.labelRegular(
      palette.muted,
    ).copyWith(fontSize: 12, height: 18 / 12);
    final String nightly = MoneyText.digits(context, room.nightlyRate.amount);
    final num total = room.stayTotal(nights).amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MoneyText(
          room.nightlyRate.amount,
          currency: room.nightlyRate.currency,
          style: AppTypography.numMd(
            palette.ink,
          ).copyWith(fontWeight: AppTypography.bold, height: 21 / 17),
          // The Figma mark is 15px tall; MoneyText draws it at 0.92×.
          markSize: 15 / 0.92,
          semanticsLabel: l10n.pricePerNight(nightly),
        ),
        const SizedBox(height: 2),
        Text(l10n.roomCardPerNight, style: caption),
        if (showStayTotal) ...<Widget>[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MoneyText(
                total,
                currency: room.nightlyRate.currency,
                style: AppTypography.numMd(
                  palette.ink,
                  size: 14,
                ).copyWith(height: 18 / 14),
                markSize: 13 / 0.92,
                semanticsLabel:
                    '${l10n.priceStayTotal(MoneyText.digits(context, total))} ${l10n.roomStayTotalLabel(nights)}',
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  l10n.roomStayTotalLabel(nights),
                  style: caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Figma `badge`: 20 tall pill, 3/9 padding, 14px filled shield-tick 5 from
/// an 11.5 Medium label.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
    required this.iconColor,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.allPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppTypography.labelRegular(foreground).copyWith(
              fontSize: 11.5,
              fontWeight: AppTypography.medium,
              height: 14 / 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// The `room card` colours: the v2 palette on light (the component's own
/// fills are the legacy teal library — see below), theme tokens on dark.
/// Shared with the available-rooms page chrome around the cards.
@immutable
class RoomCardPalette {
  const RoomCardPalette._({
    required this.surface,
    required this.ink,
    required this.muted,
    required this.hairline,
    required this.ctaBorder,
    required this.ctaText,
    required this.availableFg,
    required this.availableBg,
    required this.cancellationFg,
    required this.cancellationBg,
    required this.badgeIcon,
    required this.title,
    required this.subtitle,
    required this.link,
    required this.outline,
  });

  factory RoomCardPalette.of(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      final AppColorTokens c = context.colors;
      return RoomCardPalette._(
        surface: c.bgSurface,
        ink: c.textPrimary,
        muted: c.textSecondary,
        hairline: c.borderDefault,
        ctaBorder: c.borderStrong,
        ctaText: c.textPrimary,
        availableFg: c.successFg,
        availableBg: c.successBg,
        cancellationFg: c.infoFg,
        cancellationBg: c.infoBg,
        badgeIcon: c.textPrimary,
        title: c.textPrimary,
        subtitle: c.textSecondary,
        link: c.textPrimary,
        outline: c.borderDefault,
      );
    }
    // The Figma component is still bound to the legacy teal "slate/petrol"
    // library (`#182428` / `#667477` / `#123F46` / `#D3E5E8`); product
    // decision (2026-09-26): render it in the v2 palette like every other
    // screen — the same semantic tokens, resolved to their v2 values.
    return const RoomCardPalette._(
      surface: AppPrimitives.white,
      ink: AppPrimitives.stone950,
      muted: AppPrimitives.stone500,
      hairline: AppPrimitives.stone200,
      ctaBorder: AppPrimitives.oud100,
      ctaText: AppPrimitives.ink700,
      availableFg: AppPrimitives.green600,
      availableBg: AppPrimitives.green50,
      cancellationFg: AppPrimitives.blue600,
      cancellationBg: AppPrimitives.blue50,
      badgeIcon: AppPrimitives.badgeIcon,
      title: AppPrimitives.stone950,
      subtitle: AppPrimitives.stone500,
      link: AppPrimitives.ink700,
      outline: AppPrimitives.stone200,
    );
  }

  /// Card / chip / summary fill.
  final Color surface;

  /// Room name + prices (`text/primary`).
  final Color ink;

  /// Description, specs, captions (`text/secondary`).
  final Color muted;

  /// The card's divider (`border/default`).
  final Color hairline;

  /// "عرض التفاصيل" outline (`border/accent-subtle`) and label
  /// (`text/accent`) — the v2 secondary button.
  final Color ctaBorder;
  final Color ctaText;

  final Color availableFg;
  final Color availableBg;
  final Color cancellationFg;
  final Color cancellationBg;

  /// The badges' filled shield-tick ([AppPrimitives.badgeIcon]).
  final Color badgeIcon;

  /// Page chrome: headings (`stone/950`), secondary labels (`stone/500`),
  /// text actions (`ink/700`) and the summary card's outline (`stone/200`).
  final Color title;
  final Color subtitle;
  final Color link;
  final Color outline;
}
