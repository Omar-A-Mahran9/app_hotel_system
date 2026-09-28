import '../../../core/localization/l10n.dart';
import '../domain/entities/payment_result.dart';
import '../domain/entities/payment_status.dart';

/// Localized labels for the payment feature's enums. Keeps the enum → string
/// mapping in one place, mirroring `ReservationL10n`.
extension PaymentL10n on AppLocalizations {
  String paymentStatusLabel(PaymentStatus status) => switch (status) {
        PaymentStatus.notStarted => paymentStatusNotStarted,
        PaymentStatus.holdRequested => paymentStatusHoldRequested,
        PaymentStatus.holdActive => paymentStatusHoldActive,
        PaymentStatus.holdFailed => paymentStatusHoldFailed,
        PaymentStatus.captureRequested => paymentStatusCaptureRequested,
        PaymentStatus.captured => paymentStatusCaptured,
        PaymentStatus.captureFailed => paymentStatusCaptureFailed,
        PaymentStatus.finalSettlementRequested =>
          paymentStatusFinalSettlementRequested,
        PaymentStatus.settled => paymentStatusSettled,
        PaymentStatus.settlementFailed => paymentStatusSettlementFailed,
        PaymentStatus.cancelled => paymentStatusCancelled,
        PaymentStatus.expired => paymentStatusExpired,
        PaymentStatus.refundRequested => paymentStatusRefundRequested,
        PaymentStatus.refunded => paymentStatusRefunded,
        PaymentStatus.refundFailed => paymentStatusRefundFailed,
      };

  /// Result-screen headline for a resolved outcome.
  String paymentOutcomeTitle(PaymentOutcome outcome) => switch (outcome) {
        PaymentOutcome.held => paymentSuccessTitle,
        PaymentOutcome.pending => paymentPendingTitle,
        PaymentOutcome.failed => paymentFailedTitle,
        PaymentOutcome.cancelled => paymentCancelledTitle,
        PaymentOutcome.expired => paymentExpiredTitle,
        PaymentOutcome.notRequired => paymentNotRequiredTitle,
        PaymentOutcome.other => paymentSuccessTitle,
      };

  /// Result-screen body for a resolved outcome.
  String paymentOutcomeBody(PaymentOutcome outcome) => switch (outcome) {
        PaymentOutcome.held => paymentSuccessBody,
        PaymentOutcome.pending => paymentPendingBody,
        PaymentOutcome.failed => paymentFailedBody,
        PaymentOutcome.cancelled => paymentFailedBody,
        PaymentOutcome.expired => paymentFailedBody,
        PaymentOutcome.notRequired => paymentNotRequiredBody,
        PaymentOutcome.other => paymentSuccessBody,
      };
}
