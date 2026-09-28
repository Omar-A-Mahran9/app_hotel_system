import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';

/// Tonal status chip (e.g. "متاحة", "مؤكد", "قيد الانتظار"; Figma `Status Pill`).
/// Colour is passed in by the caller from theme/semantic tokens. Pill shape,
/// small leading icon, short 12 Regular label (v2: was 11.5 Medium). On light
/// the icon is the Figma's fixed [AppPrimitives.badgeIcon] indigo, not the
/// label colour.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.allPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(
              icon,
              size: AppIconSizes.pill,
              color: Theme.of(context).brightness == Brightness.dark
                  ? foreground
                  : AppPrimitives.badgeIcon,
            ),
            const SizedBox(width: AppSpacing.space1),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
