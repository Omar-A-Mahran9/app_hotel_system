import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/problem_report.dart';
import '../../domain/entities/submit_problem_report.dart';
import 'problem_report_providers.dart';

/// The state of the one-shot "submit problem report" action.
sealed class ProblemReportActionState {
  const ProblemReportActionState();

  bool get isSubmitting => this is ProblemReportSubmitting;

  SubmitProblemReportRequest? get requestOrNull => switch (this) {
        ProblemReportSubmitting(:final SubmitProblemReportRequest request) => request,
        ProblemReportSubmitDone(:final SubmitProblemReportRequest request) => request,
        ProblemReportSubmitFailed(:final SubmitProblemReportRequest request) => request,
        _ => null,
      };

  ProblemReport? get reportOrNull => this is ProblemReportSubmitDone
      ? (this as ProblemReportSubmitDone).report
      : null;

  Failure? get failureOrNull => this is ProblemReportSubmitFailed
      ? (this as ProblemReportSubmitFailed).failure
      : null;
}

class ProblemReportIdle extends ProblemReportActionState {
  const ProblemReportIdle();
}

class ProblemReportSubmitting extends ProblemReportActionState {
  const ProblemReportSubmitting(this.request);
  final SubmitProblemReportRequest request;
}

/// The report was created (`open`). Terminal for this request — a repeat is
/// ignored so the same report is never double-submitted from one screen.
class ProblemReportSubmitDone extends ProblemReportActionState {
  const ProblemReportSubmitDone(this.request, this.report);
  final SubmitProblemReportRequest request;
  final ProblemReport report;
}

class ProblemReportSubmitFailed extends ProblemReportActionState {
  const ProblemReportSubmitFailed(this.request, this.failure);
  final SubmitProblemReportRequest request;
  final Failure failure;
}

/// Owns the submit-problem-report action.
///
/// Guarantees mirror the other workflow controllers (`ReviewSubmissionController`,
/// `ServiceRequestController`): duplicate-submit is a no-op while submitting
/// or after a done for the same request; a stale async result is dropped when
/// a newer request superseded it; the underlying dummy source is idempotent
/// per request.
class ProblemReportSubmissionController extends Notifier<ProblemReportActionState> {
  @override
  ProblemReportActionState build() => const ProblemReportIdle();

  Future<void> submit(SubmitProblemReportRequest request) async {
    final ProblemReportActionState current = state;
    if (current is ProblemReportSubmitting && current.request == request) return;
    if (current is ProblemReportSubmitDone && current.request == request) return;

    state = ProblemReportSubmitting(request);
    try {
      final ProblemReport report =
          await ref.read(problemReportRepositoryProvider).submit(request);
      if (_superseded(request)) return;
      state = ProblemReportSubmitDone(request, report);
      ref.invalidate(problemReportsProvider(request.reservationId));
    } catch (error) {
      if (_superseded(request)) return;
      state = ProblemReportSubmitFailed(request, ErrorMapper.toFailure(error));
    }
  }

  bool _superseded(SubmitProblemReportRequest request) {
    final ProblemReportActionState now = state;
    return now is ProblemReportSubmitting && now.request != request;
  }

  void reset() => state = const ProblemReportIdle();
}

final problemReportSubmissionControllerProvider =
    NotifierProvider<ProblemReportSubmissionController, ProblemReportActionState>(
  ProblemReportSubmissionController.new,
);
