import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/result_view.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../domain/entities/problem_report.dart';
import '../state/problem_report_providers.dart';

/// `13 · Report a problem` screen 3 — "تم الإرسال". Confirms the report
/// reached reception and offers to track it. Never fabricates an SLA/ETA the
/// backend does not provide (mobile/docs/coding_rules.md §9).
class ReportProblemSubmittedPage extends ConsumerWidget {
  const ReportProblemSubmittedPage({
    super.key,
    required this.reservationId,
    required this.reportId,
  });

  final String reservationId;
  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ProblemReportKey key =
        (reservationId: reservationId, reportId: reportId);
    final AsyncValue<ProblemReport> reportAsync = ref.watch(problemReportProvider(key));

    return Scaffold(
      appBar: HotelAppBar(title: l10n.reportSubmittedTitle),
      body: SafeArea(
        child: reportAsync.when(
          loading: () => Center(child: LoadingView(label: l10n.stateLoadingTitle)),
          error: (Object e, StackTrace _) => MessageView(
            icon: AppIcons.report,
            title: l10n.reportUnavailableTitle,
            message: ErrorMapper.toFailure(e).localizedMessage(l10n),
            actionLabel: l10n.actionRetry,
            onAction: () => ref.invalidate(problemReportProvider(key)),
          ),
          data: (ProblemReport report) => _Body(reservationId: reservationId, report: report),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.reservationId, required this.report});

  final String reservationId;
  final ProblemReport report;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return Column(
      children: <Widget>[
        Expanded(
          child: ResultView(
            tone: InfoBannerTone.success,
            title: l10n.reportSubmittedBannerTitle,
            message: l10n.reportSubmittedBannerBody(report.reference),
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.xs,
            AppSpacing.pageGutter,
            AppSpacing.md,
          ),
          child: PrimaryButton(
            label: l10n.reportTrackCta,
            onPressed: () => context.pushReplacementNamed(
              AppRoutes.problemReportDetailName,
              pathParameters: <String, String>{
                'reservationId': reservationId,
                'reportId': report.id,
              },
            ),
          ),
        ),
      ],
    );
  }
}
