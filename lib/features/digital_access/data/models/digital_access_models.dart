// Data-transfer models for the digital-access feature.
//
// `AccessGrantModel` mirrors the safe Laravel `AccessGrantResource` shape
// (reservation_id, status, access_mode, provider, timestamps,
// revocation_reason, failure_reason, and `credential` — present only while
// active). The check-in request has no body (`CheckInRequest`); the
// idempotency key is an HTTP header.

import '../../domain/entities/access_grant.dart';
import '../../domain/entities/access_status.dart';

typedef Json = Map<String, Object?>;

/// Parsed `AccessGrantResource`.
class AccessGrantModel {
  const AccessGrantModel({
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

  factory AccessGrantModel.fromJson(Json json) {
    return AccessGrantModel(
      reservationId: '${json['reservation_id']}',
      status: AccessStatus.fromWire(
        (json['status'] as String?) ?? AccessStatus.notIssued.wireValue,
      ),
      mode: AccessMode.fromWire(json['access_mode'] as String?),
      // `credential` is only ever present in the payload while the grant is
      // active; carry it through untouched and never log it.
      credential: json['credential'] as String?,
      // Not part of the approved resource — tolerated when a future contract
      // adds it, otherwise null.
      roomNumber: json['room_number'] == null ? null : '${json['room_number']}',
      provider: json['provider'] as String?,
      issuedAt: _dateOrNull(json['issued_at']),
      activatedAt: _dateOrNull(json['activated_at']),
      expiresAt: _dateOrNull(json['expires_at']),
      revokedAt: _dateOrNull(json['revoked_at']),
      revocationReason: json['revocation_reason'] as String?,
      failureReason: json['failure_reason'] as String?,
    );
  }

  final String reservationId;
  final AccessStatus status;
  final AccessMode mode;
  final String? credential;
  final String? roomNumber;
  final String? provider;
  final DateTime? issuedAt;
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final String? revocationReason;
  final String? failureReason;

  AccessGrant toEntity() => AccessGrant(
        reservationId: reservationId,
        status: status,
        mode: mode,
        credential: status.isActive ? credential : null,
        roomNumber: roomNumber,
        provider: provider,
        issuedAt: issuedAt,
        activatedAt: activatedAt,
        expiresAt: expiresAt,
        revokedAt: revokedAt,
        revocationReason: revocationReason,
        failureReason: failureReason,
      );

  static DateTime? _dateOrNull(Object? raw) {
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }
}
