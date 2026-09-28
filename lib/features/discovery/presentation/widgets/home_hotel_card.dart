import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../domain/entities/hotel_summary.dart';
import 'hotel_thumbnail.dart';

/// v2 Figma `Hotel card` (`HOME_Default` rail): a full-bleed photo card,
/// radius 16, soft tile shadow, 345×229 on a 393 frame (the aspect ratio is
/// kept as the card widens).
///
/// * a black 0→42% gradient over the bottom 130px;
/// * bottom row, 16px in: the hotel name (18 Medium) and a location line
///   (14px pin + city, 14 Regular), all white, beside a 32px white circle with
///   a forward arrow;
/// * top-left, 8px in: a translucent pill (white @55%, gold number + star)
///   showing the hotel's own star classification (`starRating`, 1-5) — not
///   the guest-review average — kept on the left in both directions
///   (`design-system-tokens.md` §8).
class HomeHotelCard extends ConsumerWidget {
  const HomeHotelCard({super.key, required this.hotel, required this.onTap});

  final HotelSummary hotel;
  final VoidCallback onTap;

  /// Figma card box on the 393-wide frame.
  static const double aspectRatio = 345 / 229;

  static const double _radius = 16;

  /// Height of the bottom scrim (Figma `Frame 3`).
  static const double _scrimHeight = 130;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Locale locale = Localizations.localeOf(context);
    final TextTheme text = Theme.of(context).textTheme;
    final TextDirection direction = Directionality.of(context);
    // Dummy data never carries a per-hotel photo, so the deterministic Figma
    // seed keeps the demo looking real; a real-API hotel with no cover must
    // show the plain placeholder (hotel_thumbnail.dart's real-API contract).
    final AppConfig config = ref.watch(appConfigProvider);

    const BorderRadius radius = BorderRadius.all(Radius.circular(_radius));

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: radius,
          boxShadow: AppShadows.tile,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  HotelThumbnail(
                    imageUrl: hotel.coverUrl,
                    seed: config.useDummyData ? hotel.id : null,
                    borderRadius: BorderRadius.zero,
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _scrimHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[Color(0x00000000), Color(0x6B000000)],
                        ),
                      ),
                    ),
                  ),
                  if (hotel.starRating != null)
                    Positioned(
                      left: AppSpacing.space2,
                      top: AppSpacing.space2,
                      child: _StarClassPill(stars: hotel.starRating!),
                    ),
                  Positioned(
                    left: AppSpacing.space4,
                    right: AppSpacing.space4,
                    bottom: AppSpacing.space4,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                hotel.name.resolve(locale),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleLarge?.copyWith(
                                  color: AppPrimitives.white,
                                  fontWeight: AppTypography.medium,
                                  height: 23 / 18,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.space2),
                              Row(
                                children: <Widget>[
                                  const Icon(
                                    AppIcons.location,
                                    size: 14,
                                    color: AppPrimitives.white,
                                  ),
                                  const SizedBox(width: AppSpacing.space2),
                                  Flexible(
                                    child: Text(
                                      hotel.cityName.resolve(locale),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: text.bodySmall?.copyWith(
                                        color: AppPrimitives.white,
                                        height: 18 / 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppPrimitives.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.colors.borderDefault,
                              width: 0.36,
                            ),
                          ),
                          child: Icon(
                            AppIcons.homeCardArrowFor(direction),
                            size: 15,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Figma `Rating Badge / Size=Compact` as overridden on the hotel card: a
/// white @55% pill, 6/4 padding, gold star count (12 Medium, tabular) + star.
class _StarClassPill extends StatelessWidget {
  const _StarClassPill({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppPrimitives.white.withValues(alpha: 0.55),
        borderRadius: AppRadius.allPill,
      ),
      child: Directionality(
        // Numerals keep a fixed order in both directions.
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '$stars',
              style: AppTypography.numXs(c.accentWarm),
            ),
            const SizedBox(width: 6),
            Icon(AppIcons.homeRatingStar, size: 14, color: c.accentWarm),
          ],
        ),
      ),
    );
  }
}
