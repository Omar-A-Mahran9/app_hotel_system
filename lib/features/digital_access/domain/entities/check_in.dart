import 'package:flutter/foundation.dart';

import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/domain/entities/reservation_status.dart';
import 'access_grant.dart';

/// Everything the mobile app can supply to perform check‑in.
///
/// The approved backend `POST /api/v1/check-in/{reservation}`
/// (`CheckInRequest`) carries **no body fields** — the idempotency key is the
/// `Idempotency-Key` header. That endpoint is staff/dashboard‑scoped
/// (`ReservationService::findAccessibleBy` + `AccessGrantPolicy`), so this
/// request only carries the reservation id and derives a stable key from it.
@immutable
class CheckInRequest {
  const CheckInRequest({required this.reservationId});

  factory CheckInRequest.forReservation(Reservation reservation) =>
      CheckInRequest(reservationId: reservation.id);

  final String reservationId;

  /// Stable idempotency key — used as the `Idempotency-Key` header and to dedupe
  /// repeated submits. No time component, no randomness.
  String get idempotencyKey => 'checkin:$reservationId';

  @override
  bool operator ==(Object other) =>
      other is CheckInRequest && other.reservationId == reservationId;

  @override
  int get hashCode => reservationId.hashCode;

  @override
  String toString() => 'CheckInRequest($idempotencyKey)';
}

/// Whether the guest can start check‑in, judged only from the authoritative
/// reservation status the app already holds. The backend remains the final
/// authority (`CheckInEligibilityException`); this is a UX pre‑check, not a
/// business rule.
///
/// Phase 0 §8: a reservation reaches `VERIFIED` (deposit held + identity
/// verified) before check‑in; check‑in drives `VERIFIED → CHECKED_IN`.
enum CheckInEligibility {
  /// Reservation is `VERIFIED` — ready to check in.
  ready,

  /// Still needs the deposit hold and/or identity verification.
  notReady,

  /// Already checked in (or further along) — go straight to the access screen.
  alreadyCheckedIn,

  /// Reservation is cancelled / checked out — check‑in is not applicable.
  unavailable,

  /// VERIFIED, but the backend's check-in availability says not yet (room
  /// not assigned, reception-only hotel, …) — see [Reservation.checkInAvailability].
  blocked;

  /// The backend's decision when it sent one (API), else the status mapping
  /// (offline/demo data carries no availability).
  static CheckInEligibility forReservation(Reservation reservation) {
    final CheckInEligibility byStatus = fromReservation(reservation.status);
    final CheckInAvailability server = reservation.checkInAvailability;
    if (byStatus == CheckInEligibility.ready && server.mode != null && !server.allowed) {
      return CheckInEligibility.blocked;
    }
    return byStatus;
  }

  static CheckInEligibility fromReservation(ReservationStatus status) {
    return switch (status) {
      ReservationStatus.verified => CheckInEligibility.ready,
      ReservationStatus.pending ||
      ReservationStatus.depositHeld =>
        CheckInEligibility.notReady,
      ReservationStatus.checkedIn ||
      ReservationStatus.inStay ||
      ReservationStatus.checkoutInProgress ||
      ReservationStatus.checkoutBlocked =>
        CheckInEligibility.alreadyCheckedIn,
      ReservationStatus.checkedOut ||
      ReservationStatus.invoiced ||
      ReservationStatus.cancelled =>
        CheckInEligibility.unavailable,
    };
  }

  bool get canStart => this == CheckInEligibility.ready;
}

/// The safe, client-visible outcome of a check‑in attempt — mirrors the
/// branches of `CheckInController::store` (201 checked in / 422 issue failed /
/// other state).
enum CheckInOutcome {
  /// `AccessGrant` is `ACTIVE` — the guest is checked in and has a credential.
  checkedIn,

  /// `AccessGrant` is `FAILED` — issuance did not succeed. Safe to retry.
  issueFailed,

  /// Any other resolved grant state (issue_requested, …).
  pending;

  static CheckInOutcome fromGrant(AccessGrant grant) => switch (grant.status) {
        _ when grant.status.isActive => CheckInOutcome.checkedIn,
        _ when grant.status.isFailed => CheckInOutcome.issueFailed,
        _ => CheckInOutcome.pending,
      };

  bool get isSuccess => this == CheckInOutcome.checkedIn;
  bool get isRetryable => this == CheckInOutcome.issueFailed;
}

@immutable
class CheckInResult {
  const CheckInResult({required this.grant, required this.outcome});

  factory CheckInResult.of(AccessGrant grant) =>
      CheckInResult(grant: grant, outcome: CheckInOutcome.fromGrant(grant));

  final AccessGrant grant;
  final CheckInOutcome outcome;

  @override
  bool operator ==(Object other) =>
      other is CheckInResult &&
      other.grant == grant &&
      other.outcome == outcome;

  @override
  int get hashCode => Object.hash(grant, outcome);
}
