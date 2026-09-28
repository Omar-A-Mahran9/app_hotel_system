import 'package:flutter/foundation.dart';

import 'access_status.dart';

/// A digital-access grant as the guest app knows it.
///
/// Mirrors the safe fields of the Laravel `AccessGrantResource` (`reservation_id`,
/// `status`, `access_mode`, `provider`, `issued_at`, `activated_at`,
/// `expires_at`, `revoked_at`, `revocation_reason`, `failure_reason`, and the
/// `credential` — present ONLY while `status == active`). The provider
/// reference, `idempotency_key`, attempt metadata and any provider internals
/// are absent there and here (mobile/docs/architecture.md §8, Phase 0 §17).
///
/// SECURITY: [credential] is the one piece of sensitive data. It is held only
/// in memory on this immutable object for the lifetime of the screen, never
/// written to storage, never logged, and only ever rendered while [isActive].
///
/// [roomNumber] is **not** part of the approved `AccessGrantResource` — see the
/// integration doc. It is populated by the deterministic dummy source and left
/// `null` by the (stubbed) API source; the UI shows the row only when present.
@immutable
class AccessGrant {
  const AccessGrant({
    required this.reservationId,
    required this.status,
    required this.mode,
    this.credential,
    this.roomNumber,
    this.provider,
    this.issuedAt,
    this.activatedAt,
    this.expiresAt,
    this.revokedAt,
    this.revocationReason,
    this.failureReason,
  });

  /// A "no grant yet" record for a reservation.
  factory AccessGrant.notIssued(String reservationId) => AccessGrant(
        reservationId: reservationId,
        status: AccessStatus.notIssued,
        mode: AccessMode.pinCode,
      );

  final String reservationId;
  final AccessStatus status;
  final AccessMode mode;

  /// The app-delivered PIN. Non-null only when [isActive]. Never persisted.
  final String? credential;

  /// Friendly room number for display. Not in the approved contract yet.
  final String? roomNumber;

  final String? provider;
  final DateTime? issuedAt;
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;

  /// A safe, human‑category reason ("guest_request", "stay_ended", …) — never a
  /// provider payload.
  final String? revocationReason;
  final String? failureReason;

  bool get isActive => status.isActive;
  bool get isFailed => status.isFailed;
  bool get exists => status != AccessStatus.notIssued;

  /// The credential to show — only when the grant is genuinely active.
  String? get visibleCredential => isActive ? credential : null;

  @override
  bool operator ==(Object other) =>
      other is AccessGrant &&
      other.reservationId == reservationId &&
      other.status == status &&
      other.mode == mode &&
      other.credential == credential &&
      other.roomNumber == roomNumber &&
      other.provider == provider &&
      other.issuedAt == issuedAt &&
      other.activatedAt == activatedAt &&
      other.expiresAt == expiresAt &&
      other.revokedAt == revokedAt &&
      other.revocationReason == revocationReason &&
      other.failureReason == failureReason;

  @override
  int get hashCode => Object.hashAll(<Object?>[
        reservationId,
        status,
        mode,
        credential,
        roomNumber,
        provider,
        issuedAt,
        activatedAt,
        expiresAt,
        revokedAt,
        revocationReason,
        failureReason,
      ]);

  @override
  String toString() =>
      'AccessGrant($reservationId, ${status.wireValue})'; // never prints credential
}
