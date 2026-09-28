import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icons.dart';

/// The rounded search field from `02 · Discover & Book` — a search icon, the
/// field, an optional clear button and an optional trailing filter/sort button.
///
/// On the discover screen it is read-only ([onTap] navigates to the search
/// screen); on the search screen it is a live [TextField].
class HotelSearchField extends StatelessWidget {
  const HotelSearchField({
    super.key,
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.onClear,
    this.onFilterTap,
    this.filterBadgeCount = 0,
    this.trailingIcon,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final int filterBadgeCount;

  /// A static glyph shown inside the field on its trailing edge (`end` — the
  /// left in RTL) when there is no clear button to show, e.g. the read-only
  /// Home field's filter/list glyph (`HOME_Default`). Purely decorative: the
  /// whole field already navigates on tap, so this never gets its own
  /// [onFilterTap]-style handler.
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = context.l10n;
    final bool hasText = (controller?.text ?? '').isNotEmpty;

    return Row(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: 47,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onTap: onTap,
              readOnly: readOnly,
              autofocus: autofocus,
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.discoverSearchHint,
                hintStyle: theme.textTheme.labelSmall,
                prefixIcon: const Icon(AppIcons.search, size: 18),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 42,
                  minHeight: 47,
                ),
                suffixIcon: hasText && onClear != null
                    ? IconButton(
                        icon: const Icon(AppIcons.close, size: 18),
                        tooltip: l10n.searchClearTooltip,
                        onPressed: onClear,
                      )
                    : trailingIcon != null
                    ? Icon(trailingIcon, size: 18)
                    : null,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 47,
                ),
                border: const OutlineInputBorder(
                  borderRadius: AppRadius.allPill,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.allPill,
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.allPill,
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (onFilterTap != null) ...<Widget>[
          const SizedBox(width: AppSpacing.xs),
          _FilterButton(count: filterBadgeCount, onTap: onFilterTap!),
        ],
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Tooltip(
      message: context.l10n.filterTitle,
      child: InkWell(
        borderRadius: AppRadius.allPill,
        onTap: onTap,
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Icon(
                AppIcons.filter,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
              if (count > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
