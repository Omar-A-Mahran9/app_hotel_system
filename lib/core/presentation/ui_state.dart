import '../errors/failure.dart';

/// The canonical screen/section state every feature represents
/// (mobile/docs/feature_guide.md Step 6). Workflow features that must mirror a
/// backend state machine (reservations, payments, identity) model those states
/// explicitly on top of this — they do not collapse everything to success.
sealed class UiState<T> {
  const UiState();

  const factory UiState.initial() = UiInitial<T>;
  const factory UiState.loading() = UiLoading<T>;
  const factory UiState.success(T data) = UiSuccess<T>;
  const factory UiState.empty() = UiEmpty<T>;
  const factory UiState.failure(Failure failure) = UiFailure<T>;

  R map<R>({
    required R Function() initial,
    required R Function() loading,
    required R Function(T data) success,
    required R Function() empty,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      UiInitial<T>() => initial(),
      UiLoading<T>() => loading(),
      UiSuccess<T>(:final T data) => success(data),
      UiEmpty<T>() => empty(),
      UiFailure<T>(failure: final Failure f) => failure(f),
    };
  }
}

class UiInitial<T> extends UiState<T> {
  const UiInitial();
}

class UiLoading<T> extends UiState<T> {
  const UiLoading();
}

class UiSuccess<T> extends UiState<T> {
  const UiSuccess(this.data);
  final T data;
}

class UiEmpty<T> extends UiState<T> {
  const UiEmpty();
}

class UiFailure<T> extends UiState<T> {
  const UiFailure(this.failure);
  final Failure failure;
}
