import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/review.dart';
import '../reviews_l10n.dart';

/// Tonal chip for a [ReviewStatus], built on the design-system [StatusPill].
/// Colour is derived from the status only — the backend stays authoritative for
/// the moderation state.
class ReviewStatusPill extends StatelessWidget {
  const ReviewStatusPill({super.key, required this.status});

  final ReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppColorTokens c = context.colors;

    final (Color fg, Color bg) = switch (status) {
      ReviewStatus.pending => (c.warningFg, c.warningBg),
      ReviewStatus.published => (c.successFg, c.successBg),
      ReviewStatus.rejected => (c.errorFg, c.errorBg),
    };

    return StatusPill(
      label: l10n.reviewStatusLabel(status),
      foreground: fg,
      background: bg,
      icon: Icons.circle,
    );
  }
}
