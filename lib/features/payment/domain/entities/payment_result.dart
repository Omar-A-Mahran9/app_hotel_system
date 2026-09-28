import 'package:flutter/foundation.dart';

import 'payment.dart';
import 'payment_status.dart';

/// The safe, client-visible outcome of a hold request.
///
/// The backend `PaymentController::hold` maps the resolved `Payment` status to
/// one of a small set of HTTP shapes (201 hold placed, 200 hold pending, 422
/// hold failed / cancelled / expired). This mirrors that classification so the
/// result screen renders the right message without re-deriving it from the raw
/// status everywhere.
enum PaymentOutcome {
  /// `HOLD_ACTIVE` — the deposit authorization is in place.
  held,

  /// `HOLD_REQUESTED` — accepted, still resolving (e.g. awaiting the provider
  /// webhook). The guest can refresh the status later.
  pending,

  /// `HOLD_FAILED` — the attempt did not succeed. Safe to retry.
  failed,

  /// `CANCELLED` — the hold was cancelled before it went active.
  cancelled,

  /// `EXPIRED` — the hold window lapsed.
  expired,

  /// The hotel takes no deposit — the reservation is already confirmed.
  notRequired,

  /// Any other resolved status (already captured, settled, …) — shown as-is.
  other;

  static PaymentOutcome fromStatus(PaymentStatus status) => switch (status) {
        PaymentStatus.holdActive => PaymentOutcome.held,
        PaymentStatus.holdRequested => PaymentOutcome.pending,
        PaymentStatus.holdFailed => PaymentOutcome.failed,
        PaymentStatus.cancelled => PaymentOutcome.cancelled,
        PaymentStatus.expired => PaymentOutcome.expired,
        _ => status.isSecured ? PaymentOutcome.held : PaymentOutcome.other,
      };

  bool get isSuccess =>
      this == PaymentOutcome.held ||
      this == PaymentOutcome.notRequired ||
      this == PaymentOutcome.other;

  bool get isRetryable => switch (this) {
        PaymentOutcome.failed ||
        PaymentOutcome.cancelled ||
        PaymentOutcome.expired =>
          true,
        _ => false,
      };
}

/// A resolved payment plus its safe outcome classification.
@immutable
class PaymentResult {
  const PaymentResult({required this.payment, required this.outcome});

  factory PaymentResult.of(Payment payment) => PaymentResult(
        payment: payment,
        outcome: payment.depositRequired
            ? PaymentOutcome.fromStatus(payment.status)
            : PaymentOutcome.notRequired,
      );

  final Payment payment;
  final PaymentOutcome outcome;

  PaymentStatus get status => payment.status;

  @override
  bool operator ==(Object other) =>
      other is PaymentResult &&
      other.payment == payment &&
      other.outcome == outcome;

  @override
  int get hashCode => Object.hash(payment, outcome);

  @override
  String toString() => 'PaymentResult(${outcome.name}, ${status.wireValue})';
}
