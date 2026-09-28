import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// A Home section title with an optional trailing "عرض الكل" action — v2 Figma
/// `Section Header` (32 tall, title at the start, action at the end).
///
/// Two title sizes are used on Home:
/// * default — 18 Bold (`HOME_if One hotel` headers);
/// * [compact] — 16 Medium, no action (`HOME_Default` explore header and the
///   next-stay header).
///
/// [onTap] makes the whole header tappable (the `HOME_Default` explore header
/// opens search).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.onTap,
    this.compact = false,
  });

  final String title;
  final VoidCallback? onSeeAll;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppColorTokens c = context.colors;

    final TextStyle? titleStyle = compact
        ? text.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: AppTypography.medium,
            color: c.textPrimary,
          )
        : text.titleLarge?.copyWith(color: c.textPrimary);

    final Widget row = SizedBox(
      height: 32,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: titleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  context.l10n.commonSeeAll,
                  style: text.labelMedium?.copyWith(color: c.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
