import '../../../reservation/domain/entities/reservation_status.dart';

/// Whether the guest can start (or continue) identity verification, judged
/// only from the authoritative reservation status the app already holds — a
/// UX pre-check, not a business rule; the backend session status machine
/// (`identity_verification_status.dart`) stays authoritative for the flow
/// itself once eligible.
///
/// Mirrors `CheckInEligibility` (`digital_access/domain/entities/check_in.dart`):
/// Phase 0 §8 requires the deposit hold (`DEPOSIT_HELD`) before identity
/// verification is meaningful, and a reservation past `VERIFIED` has already
/// completed it.
enum IdentityVerificationEligibility {
  /// Reservation is `DEPOSIT_HELD` — ready to verify identity.
  ready,

  /// Still needs the deposit hold first.
  notReady,

  /// Reservation is `VERIFIED` or later — identity is already confirmed.
  alreadyVerified,

  /// Reservation is cancelled — verification is not applicable.
  unavailable;

  static IdentityVerificationEligibility fromReservation(
    ReservationStatus status,
  ) {
    return switch (status) {
      ReservationStatus.depositHeld => IdentityVerificationEligibility.ready,
      ReservationStatus.pending => IdentityVerificationEligibility.notReady,
      ReservationStatus.verified ||
      ReservationStatus.checkedIn ||
      ReservationStatus.inStay ||
      ReservationStatus.checkoutInProgress ||
      ReservationStatus.checkoutBlocked ||
      ReservationStatus.checkedOut ||
      ReservationStatus.invoiced =>
        IdentityVerificationEligibility.alreadyVerified,
      ReservationStatus.cancelled =>
        IdentityVerificationEligibility.unavailable,
    };
  }
}
