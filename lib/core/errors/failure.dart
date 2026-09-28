/// User-safe classification of an error, produced by [ErrorMapper] and consumed
/// by the presentation layer to pick a localized message and recovery action.
enum FailureKind {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  conflict,
  rateLimited,
  server,
  notImplemented,
  unknown,
}

/// Immutable, presentation-friendly error. Carries no stack traces or raw
/// server payloads (mobile/docs/coding_rules.md §9).
class Failure {
  const Failure(
    this.kind, {
    this.fieldErrors = const <String, List<String>>{},
    this.debugMessage,
  });

  final FailureKind kind;

  /// Populated only for [FailureKind.validation]; keyed by request field.
  final Map<String, List<String>> fieldErrors;

  /// Non-localized detail for logs and tests. Never render this to a user.
  final String? debugMessage;

  bool get isRetryable => switch (kind) {
        FailureKind.network ||
        FailureKind.timeout ||
        FailureKind.server ||
        FailureKind.rateLimited ||
        FailureKind.unknown =>
          true,
        _ => false,
      };

  @override
  bool operator ==(Object other) =>
      other is Failure &&
      other.kind == kind &&
      other.debugMessage == debugMessage;

  @override
  int get hashCode => Object.hash(kind, debugMessage);

  @override
  String toString() => 'Failure(${kind.name}${debugMessage == null ? '' : ': $debugMessage'})';
}
