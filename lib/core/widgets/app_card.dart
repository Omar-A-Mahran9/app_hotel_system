import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// The Figma `Card` component's `Style` axis.
enum AppCardStyle {
  /// Surface fill + resting shadow, no border.
  elevated,

  /// Surface fill + 1px hairline + resting shadow (the default; matches most
  /// list-container cards).
  outlined,

  /// Flat `bg/subtle` fill, no border or shadow — for nested / secondary cards.
  subtle,

  /// Flat `bg/inverse` (brown) fill — the loyalty balance / digital-key hero.
  /// Children must use on-inverse colours (`context.colors.textOnInverse`).
  inverse,
}

/// Surface container from the design system. Pick a [style]; the legacy
/// [border] / [shadow] booleans still work when no [style] is given.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.onTap,
    this.style,
    this.border = true,
    this.shadow = true,
    this.color,
    this.radius = AppRadius.allCard,
  });

  /// A card with no inner padding — for list containers that draw their own row
  /// insets and dividers.
  const AppCard.list({
    super.key,
    required this.child,
    this.onTap,
    this.style,
    this.border = true,
    this.shadow = true,
    this.color,
    this.radius = AppRadius.allCard,
  }) : padding = EdgeInsets.zero;

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final AppCardStyle? style;
  final bool border;
  final bool shadow;
  final Color? color;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorTokens c = context.colors;
    final bool isLight = theme.brightness == Brightness.light;

    final AppCardStyle resolved =
        style ?? (border ? AppCardStyle.outlined : AppCardStyle.elevated);

    final Color fill = color ??
        switch (resolved) {
          AppCardStyle.elevated || AppCardStyle.outlined => c.bgSurface,
          AppCardStyle.subtle => c.bgSubtle,
          AppCardStyle.inverse => c.bgInverse,
        };
    final bool hasBorder = resolved == AppCardStyle.outlined;
    final bool hasShadow = shadow &&
        isLight &&
        (resolved == AppCardStyle.elevated ||
            resolved == AppCardStyle.outlined);

    final Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: hasBorder ? Border.all(color: c.borderDefault) : null,
        boxShadow: hasShadow ? AppShadows.card : AppShadows.none,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(borderRadius: radius, onTap: onTap, child: content),
    );
  }
}
