import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_icons.dart';

/// Tone of an [InfoBanner], mapped to the design system's `color/state/*` set.
enum InfoBannerTone { info, success, warning, error }

/// Tinted, rounded message block with a leading icon badge — the canonical
/// Figma pattern for **success / error / warning / info** notices and for the
/// header block on result screens (`تم التحقق وتأكيد حجزك`, `الرمز غير صحيح`,
/// `تعذر رفع الصور`, …). Also covers the `Toast` component's tones.
///
/// Copy is passed in by the caller; the block lays out correctly in RTL and
/// LTR. For a result screen, pass [child] (details) and/or use
/// `BottomActionBar` for the actions beneath it.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.tone,
    required this.title,
    this.message,
    this.child,
    this.dense = false,
  });

  final InfoBannerTone tone;
  final String title;
  final String? message;

  /// Optional extra content rendered below the message (e.g. a reference code,
  /// a small summary row) — used by result screens.
  final Widget? child;

  /// Tighter padding for inline use inside lists.
  final bool dense;

  ({Color fg, Color bg, Color border, IconData icon}) _spec(
    AppColorTokens c,
  ) {
    return switch (tone) {
      InfoBannerTone.info => (
        fg: c.infoFg,
        bg: c.infoBg,
        border: c.infoBorder,
        icon: AppIcons.infoOutline,
      ),
      InfoBannerTone.success => (
        fg: c.successFg,
        bg: c.successBg,
        border: c.successBorder,
        icon: AppIcons.infoOutline,
      ),
      InfoBannerTone.warning => (
        fg: c.warningFg,
        bg: c.warningBg,
        border: c.warningBorder,
        icon: AppIcons.infoOutline,
      ),
      InfoBannerTone.error => (
        fg: c.errorFg,
        bg: c.errorBg,
        border: c.errorBorder,
        icon: AppIcons.errorOutline,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppColorTokens c = context.colors;
    final spec = _spec(c);

    // v2 `Message` component: tone fill + 1px tone stroke, radius 20, 16px
    // padding, a 20px linear glyph 12px from the text; title 14.5 bold and
    // body 13.5 in the tone colour (body at 85%).
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(dense ? AppSpacing.space3 : AppSpacing.space4),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: spec.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(spec.icon, size: dense ? 18 : 20, color: c.textPrimary),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: spec.fg,
                    fontSize: 14.5,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (message != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.space1),
                  Text(
                    message!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: spec.fg.withValues(alpha: 0.85),
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ],
                if (child != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.space3),
                  child!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
