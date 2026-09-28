import '../errors/failure.dart';

/// Progress of a one-shot form submission (send code, verify, save profile).
///
/// Complements [UiState], which models a screen's *content*. A submission has no
/// "content" — only idle / in-progress / failed — so collapsing it into
/// `UiState` or a pair of `isLoading` / `error` booleans would be a worse fit
/// (feature_guide.md Step 6, phase brief — "Prefer explicit states").
sealed class FormSubmission {
  const FormSubmission();

  const factory FormSubmission.idle() = SubmissionIdle;
  const factory FormSubmission.inProgress() = SubmissionInProgress;
  const factory FormSubmission.failed(Failure failure) = SubmissionFailed;

  bool get isInProgress => this is SubmissionInProgress;

  Failure? get failureOrNull =>
      this is SubmissionFailed ? (this as SubmissionFailed).failure : null;

  T map<T>({
    required T Function() idle,
    required T Function() inProgress,
    required T Function(Failure failure) failed,
  }) {
    return switch (this) {
      SubmissionIdle() => idle(),
      SubmissionInProgress() => inProgress(),
      SubmissionFailed(:final Failure failure) => failed(failure),
    };
  }
}

class SubmissionIdle extends FormSubmission {
  const SubmissionIdle();
}

class SubmissionInProgress extends FormSubmission {
  const SubmissionInProgress();
}

class SubmissionFailed extends FormSubmission {
  const SubmissionFailed(this.failure);
  final Failure failure;

  @override
  bool operator ==(Object other) =>
      other is SubmissionFailed && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}
