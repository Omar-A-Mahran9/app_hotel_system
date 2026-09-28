import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/problem_category.dart';
import '../../domain/entities/problem_urgency.dart';
import '../../domain/entities/submit_problem_report.dart';
import '../state/problem_report_submission_controller.dart';
import '../widgets/urgency_selector.dart';

/// `13 · Report a problem` screen 2 — "وصف المشكلة". Urgency (defaults to
/// `important`, matching the Figma board's pre-selected state) + an optional
/// note, then submit.
///
/// The Figma board's info banner and prompt copy for this screen were
/// evidently reused from a "schedule cleaning" mockup (its wording only makes
/// sense for the room-cleanliness category) — the copy here is a
/// category-agnostic equivalent so it reads correctly for every category,
/// and it does not claim a specific response time the backend does not
/// promise (mobile/docs/coding_rules.md §9 — never fabricate data for the
/// user).
class ReportProblemDescriptionPage extends ConsumerStatefulWidget {
  const ReportProblemDescriptionPage({
    super.key,
    required this.reservationId,
    required this.category,
  });

  final String reservationId;
  final ProblemCategory category;

  @override
  ConsumerState<ReportProblemDescriptionPage> createState() =>
      _ReportProblemDescriptionPageState();
}

class _ReportProblemDescriptionPageState
    extends ConsumerState<ReportProblemDescriptionPage> {
  final TextEditingController _notes = TextEditingController();
  ProblemUrgency _urgency = ProblemUrgency.important;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);

    final String? notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final SubmitProblemReportRequest request = SubmitProblemReportRequest(
      reservationId: widget.reservationId,
      category: widget.category,
      urgency: _urgency,
      notes: notes,
    );

    final ProblemReportActionState action =
        ref.watch(problemReportSubmissionControllerProvider);
    final bool submitting =
        action is ProblemReportSubmitting && action.request == request;
    final Failure? failure = action is ProblemReportSubmitFailed &&
            action.request.reservationId == widget.reservationId &&
            action.request.category == widget.category
        ? action.failure
        : null;

    ref.listen<ProblemReportActionState>(
      problemReportSubmissionControllerProvider,
      (ProblemReportActionState? _, ProblemReportActionState next) {
        if (next is ProblemReportSubmitDone &&
            next.request.reservationId == widget.reservationId &&
            next.request.category == widget.category) {
          context.pushReplacementNamed(
            AppRoutes.reportProblemSubmittedName,
            pathParameters: <String, String>{
              'reservationId': widget.reservationId,
              'reportId': next.report.id,
            },
          );
        }
      },
    );

    return Scaffold(
      appBar: HotelAppBar(title: l10n.reportDescriptionTitle),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.pageGutter),
                children: <Widget>[
                  Text(l10n.reportUrgencyHeading, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  UrgencySelector(
                    urgency: _urgency,
                    onChanged: submitting
                        ? null
                        : (ProblemUrgency u) => setState(() => _urgency = u),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.reportNotesLabel,
                    hintText: l10n.reportNotesHint,
                    controller: _notes,
                    enabled: !submitting,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InfoBanner(
                    dense: true,
                    tone: InfoBannerTone.info,
                    title: l10n.reportNoFeeTitle,
                    message: l10n.reportNoFeeBody,
                  ),
                  if (failure != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    InfoBanner(
                      tone: InfoBannerTone.error,
                      title: l10n.reportFailedTitle,
                      message: failure.localizedMessage(l10n),
                    ),
                  ],
                ],
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
                label: submitting ? l10n.reportSubmittingCta : l10n.reportSubmitCta,
                isLoading: submitting,
                onPressed: submitting
                    ? null
                    : () => ref
                        .read(problemReportSubmissionControllerProvider.notifier)
                        .submit(request),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
