import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/problem_category.dart';

/// One selectable row in the `13 · Report a problem` screen-1 category list —
/// a leading icon tile + label, with a selected tint. Two of these are
/// grouped per [AppCard.list] in the page; this widget only draws the row.
class ProblemCategoryRow extends StatelessWidget {
  const ProblemCategoryRow({
    super.key,
    required this.category,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
  });

  final ProblemCategory category;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorTokens c = context.colors;

    return Column(
      children: <Widget>[
        InkWell(
          onTap: onTap,
          child: Container(
            color: selected ? c.bgSubtle : Colors.transparent,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space3,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? c.bgInverse : c.bgSubtle,
                    borderRadius: AppRadius.allMd,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected ? c.textOnInverse : c.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Text(label, style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(height: 1, color: c.borderDefault),
      ],
    );
  }
}
