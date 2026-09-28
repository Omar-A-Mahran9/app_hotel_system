import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/problem_report.dart';
import '../problem_reports_l10n.dart';
import 'problem_report_status_pill.dart';

/// A row in the "my reports" list — the list-screen analogue of
/// `ServiceOrderCard`.
class ProblemReportCard extends StatelessWidget {
  const ProblemReportCard({super.key, required this.report, required this.onTap});

  final ProblemReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final MaterialLocalizations ml = MaterialLocalizations.of(context);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.problemCategoryLabel(report.category),
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(report.reference, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  ml.formatMediumDate(report.createdAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ProblemReportStatusPill(status: report.status),
        ],
      ),
    );
  }
}
