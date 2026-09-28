import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';

/// The Figma `Icon Button` component — a 44×44 rounded hit target holding a
/// single glyph. `Style` picks the ground; `selected` is the component's
/// Selected state (a filled primary chip).
enum AppIconButtonStyle {
  /// On a light surface — subtle bordered chip.
  surface,

  /// On a dark / photographic ground — translucent scrim chip.
  dark,
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.style = AppIconButtonStyle.surface,
    this.selected = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final AppIconButtonStyle style;
  final bool selected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;

    final (Color bg, Color fg, Color border) = switch ((style, selected)) {
      (_, true) => (c.bgPrimary, c.textOnPrimary, c.bgPrimary),
      (AppIconButtonStyle.surface, false) => (
        c.bgSurface,
        c.textPrimary,
        c.borderDefault,
      ),
      (AppIconButtonStyle.dark, false) => (
        c.bgInverse.withValues(alpha: 0.55),
        c.textOnInverse,
        Colors.transparent,
      ),
    };

    final Widget button = Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.allInput,
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox.square(
          dimension: AppSizes.iconButton,
          child: Icon(icon, size: AppIconSizes.appBar, color: fg),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
