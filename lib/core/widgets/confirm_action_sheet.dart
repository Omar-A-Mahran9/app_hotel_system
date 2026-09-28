import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_icons.dart';
import 'danger_button.dart';

/// The v2 destructive confirmation sheet (`BOOKING_Cancel_Confirm_Overlay`):
/// drag handle, the bold warning glyph, title, message, a red confirm
/// action and a plain "تراجع". Resolves to `true` only when confirmed.
Future<bool> showConfirmActionSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final bool? confirmed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (BuildContext ctx) {
      final TextTheme text = Theme.of(ctx).textTheme;
      final AppColorTokens c = ctx.colors;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(AppIcons.error, size: 28, color: c.textPrimary),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: c.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: DangerButton(label: confirmLabel, onPressed: () => Navigator.of(ctx).pop(true)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(cancelLabel, style: text.bodyLarge?.copyWith(color: c.textPrimary)),
              ),
            ],
          ),
        ),
      );
    },
  );
  return confirmed ?? false;
}
