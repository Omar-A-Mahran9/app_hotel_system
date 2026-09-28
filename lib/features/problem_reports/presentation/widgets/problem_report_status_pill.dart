import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/problem_report_status.dart';
import '../problem_reports_l10n.dart';

/// Tonal chip for a [ProblemReportStatus], built on the design-system
/// [StatusPill]. Colour is derived from the status only — the backend stays
/// authoritative for the triage state.
class ProblemReportStatusPill extends StatelessWidget {
  const ProblemReportStatusPill({super.key, required this.status});

  final ProblemReportStatus status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppColorTokens c = context.colors;

    final (Color fg, Color bg) = switch (status) {
      ProblemReportStatus.open => (c.warningFg, c.warningBg),
      ProblemReportStatus.inProgress => (c.infoFg, c.infoBg),
      ProblemReportStatus.resolved => (c.successFg, c.successBg),
    };

    return StatusPill(
      label: l10n.problemReportStatusLabel(status),
      foreground: fg,
      background: bg,
      icon: Icons.circle,
    );
  }
}
