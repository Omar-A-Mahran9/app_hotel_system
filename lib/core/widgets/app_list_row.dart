import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The Figma `List Row` component's `Style` axis — a label/value line as used in
/// invoice, folio and payment summaries.
enum AppListRowStyle {
  /// Regular line — secondary label, primary value.
  regular,

  /// De-emphasised line — both label and value muted (e.g. a sub-charge).
  muted,

  /// Total line — heavier label + value, for the settled/grand-total row.
  total,
}

class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.label,
    required this.value,
    this.style = AppListRowStyle.regular,
  });

  /// Plain label text; wrapped in the row's own style.
  final String label;

  /// Trailing content — usually a `Text` or a `MoneyText`.
  final Widget value;

  final AppListRowStyle style;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? labelStyle = switch (style) {
      AppListRowStyle.regular => theme.textTheme.bodyMedium,
      AppListRowStyle.muted => theme.textTheme.bodySmall,
      AppListRowStyle.total => AppTypography.bodyStrong(
        theme.colorScheme.onSurface,
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: Text(label, style: labelStyle)),
          const SizedBox(width: AppSpacing.space3),
          DefaultTextStyle.merge(
            style: style == AppListRowStyle.total
                ? AppTypography.bodyStrong(theme.colorScheme.onSurface)
                : theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
            child: value,
          ),
        ],
      ),
    );
  }
}
