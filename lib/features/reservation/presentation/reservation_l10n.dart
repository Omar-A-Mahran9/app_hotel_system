import '../../../core/localization/l10n.dart';
import '../domain/entities/reservation_status.dart';

/// Localized labels for the reservation feature's enum. Keeps the enum → string
/// mapping in one place, mirroring `DiscoveryL10n`.
extension ReservationL10n on AppLocalizations {
  String reservationStatusLabel(ReservationStatus status) => switch (status) {
        ReservationStatus.pending => reservationStatusPending,
        ReservationStatus.depositHeld => reservationStatusDepositHeld,
        ReservationStatus.verified => reservationStatusVerified,
        ReservationStatus.checkedIn => reservationStatusCheckedIn,
        ReservationStatus.inStay => reservationStatusInStay,
        ReservationStatus.checkoutInProgress =>
          reservationStatusCheckoutInProgress,
        ReservationStatus.checkoutBlocked => reservationStatusCheckoutBlocked,
        ReservationStatus.checkedOut => reservationStatusCheckedOut,
        ReservationStatus.invoiced => reservationStatusInvoiced,
        ReservationStatus.cancelled => reservationStatusCancelled,
      };
}
