/// Internal, developer-facing error types raised by the data layer.
///
/// These are never shown to users directly — the presentation layer converts a
/// [Failure] into a localized message (mobile/docs/coding_rules.md §9). Messages
/// carried here are for logs/tests only and must not contain secrets or
/// sensitive identity/payment data.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  /// HTTP status this maps to, when it originated from a response.
  int? get statusCode => null;

  @override
  String toString() => '$runtimeType(${statusCode ?? '-'}): $message';
}

/// No connectivity / DNS / socket failure before a response was received.
class NetworkException extends AppException {
  const NetworkException({String message = 'Network unavailable', super.cause})
      : super(message);
}

/// A request exceeded the configured send/receive timeout.
class RequestTimeoutException extends AppException {
  const RequestTimeoutException({String message = 'Request timed out', super.cause})
      : super(message);
}

/// 401 — missing/expired credentials.
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized']);

  @override
  int get statusCode => 401;
}

/// 403 — authenticated but not permitted.
class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'Forbidden']);

  @override
  int get statusCode => 403;
}

/// 404 — resource does not exist / not visible to this guest.
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found']);

  @override
  int get statusCode => 404;
}

/// 409 — state conflict (e.g. an invalid reservation transition).
class ConflictException extends AppException {
  const ConflictException([super.message = 'Conflict']);

  @override
  int get statusCode => 409;
}

/// 422 — validation errors, keyed by request field, matching the Laravel
/// `{ success:false, message, errors:{field:[...]} }` envelope.
class ValidationException extends AppException {
  const ValidationException(
    this.fieldErrors, [
    super.message = 'Validation failed',
  ]);

  final Map<String, List<String>> fieldErrors;

  @override
  int get statusCode => 422;
}

/// 429 — rate limited (mobile/docs/guides/rate_limiting.md).
class RateLimitException extends AppException {
  const RateLimitException({String message = 'Too many requests', this.retryAfter})
      : super(message);

  final Duration? retryAfter;

  @override
  int get statusCode => 429;
}

/// 5xx — server-side failure.
class ServerException extends AppException {
  const ServerException({String message = 'Server error', this.statusCode = 500})
      : super(message);

  @override
  final int statusCode;
}

/// Raised by API data sources whose endpoint is not part of the approved
/// Phase 0 contract yet. Keeps "stub" behaviour explicit rather than silent.
class NotImplementedInPhaseException extends AppException {
  const NotImplementedInPhaseException([
    super.message = 'Not implemented in the current phase',
  ]);
}

/// Anything not otherwise classified.
class UnknownException extends AppException {
  const UnknownException({String message = 'Unknown error', super.cause})
      : super(message);
}
