import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'button_spinner.dart';

/// Destructive action button — the solid red pill from the Figma cancel flows
/// (`تأكيد الإلغاء` on "إلغاء الحجز؟" / "إلغاء الطلب"; Figma `Button`,
/// `Variant=Destructive`).
///
/// Reusable **visual** component only — no cancellation business logic; callers
/// wire [onPressed] to their existing controller.
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.size,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final AppButtonSize? size;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isLoading;
    final AppColorTokens colors = context.colors;
    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: colors.bgDestructive,
        foregroundColor: colors.textOnPrimary,
        disabledBackgroundColor: colors.bgDisabled,
        disabledForegroundColor: colors.textDisabled,
        minimumSize: Size.fromHeight(size?.height ?? AppSizes.buttonMedium),
        textStyle: size == AppButtonSize.large
            ? AppTypography.buttonLarge(null)
            : AppTypography.button(null),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allPill),
        elevation: 0,
      ),
      child: isLoading
          ? ButtonSpinner(color: colors.textOnPrimary)
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
