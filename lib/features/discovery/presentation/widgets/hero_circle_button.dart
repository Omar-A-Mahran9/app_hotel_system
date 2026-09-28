import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A circular, translucent-scrim icon button floated over a full-bleed hero
/// image (`HOTEL_Detail`, `08 · تفاصيل الغرفة`). Used for back / share.
class HeroCircleButton extends StatelessWidget {
  const HeroCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPrimitives.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        iconSize: 20,
        color: AppPrimitives.stone900,
        icon: Icon(icon),
      ),
    );
  }
}
