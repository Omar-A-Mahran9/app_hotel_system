import 'package:flutter/material.dart';

import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// The sticky bottom action area used across the Figma flows — one primary CTA,
/// optionally a secondary/tertiary action beneath it, on a surface that lifts
/// off the content with a soft top shadow.
///
/// Centralises the [SafeArea] handling, gutters and vertical rhythm that every
/// screen was re-deriving by hand. Pass it to `Scaffold.bottomNavigationBar`.
///
/// This phase adds the component; screens adopt it as they are migrated.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.children,
    this.spacing = AppSpacing.xs,
    this.floating = true,
  });

  /// Convenience for the common one/two-button case.
  BottomActionBar.actions({
    super.key,
    required Widget primary,
    Widget? secondary,
    Widget? note,
    this.spacing = AppSpacing.xs,
    this.floating = true,
  }) : children = <Widget>[?note, primary, ?secondary];

  final List<Widget> children;
  final double spacing;

  /// When true, paints the surface + top shadow. Set false when the bar sits
  /// directly on a matching-colour scaffold and needs no separation.
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < children.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: spacing),
          children[i],
        ],
      ],
    );

    // v2 `page footer`: 24px sides, 16px below the buttons *on top of* the
    // home-indicator inset (not merged into it).
    final Widget padded = SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageGutter,
          AppSpacing.bottomBarTop,
          AppSpacing.pageGutter,
          AppSpacing.bottomBarBottom,
        ),
        child: column,
      ),
    );

    if (!floating) return padded;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: theme.brightness == Brightness.light
            ? AppShadows.raised
            : AppShadows.none,
      ),
      child: padded,
    );
  }
}
