import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'button_spinner.dart';

/// Secondary action button from the design system (Figma `Button`,
/// `Variant=Secondary`).
///
/// An unfilled pill with a 1.5px `border/accent-subtle` outline and
/// `text/accent` label (v2 `Variant=Secondary`; `تغيير رقم الجوال`,
/// `عرض حجوزاتي`). Fill + border + pill shape come from
/// [ThemeData.outlinedButtonTheme]; pass [size] for the Small / Medium / Large
/// axis. This widget only composes the icon + label.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.size,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AppButtonSize? size;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: size == null
          ? null
          : OutlinedButton.styleFrom(
              minimumSize: Size.fromHeight(size!.height),
              textStyle: size == AppButtonSize.large
                  ? AppTypography.buttonLarge(null)
                  : null,
            ),
      child: isLoading
          ? ButtonSpinner(color: Theme.of(context).colorScheme.onSurface)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: AppIconSizes.button),
                  const SizedBox(width: AppSpacing.space2),
                ],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );
  }
}
