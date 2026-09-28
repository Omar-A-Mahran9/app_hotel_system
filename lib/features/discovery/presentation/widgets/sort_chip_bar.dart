import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/hotel_sort.dart';
import '../discovery_l10n.dart';

/// The quick-sort chip row under the search field (`HOME_Default` /
/// `SEARCH_Results_Default`). The selected chip is a filled brown pill; the rest
/// are hairline-outlined pills on the page ground.
///
/// `الأقرب` (nearest) from the mockup is intentionally absent — it needs the
/// guest's location, a later phase (`docs/mobile-discover-book.md`).
class SortChipBar extends StatelessWidget {
  const SortChipBar({super.key, required this.selected, required this.onSelected});

  final HotelSort selected;
  final ValueChanged<HotelSort> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (final HotelSort sort in HotelSort.values) ...<Widget>[
            _Chip(
              label: l10n.hotelSortLabel(sort),
              selected: selected == sort,
              onTap: () => onSelected(sort),
            ),
            if (sort != HotelSort.values.last)
              const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    final Color fg = selected ? c.textOnPrimary : c.textLabel;
    return Material(
      color: selected ? c.bgPrimary : c.bgSurface,
      shape: StadiumBorder(
        side: selected
            ? BorderSide.none
            : BorderSide(color: c.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          child: Text(
            label,
            style: AppTypography.labelStrong(fg),
          ),
        ),
      ),
    );
  }
}
