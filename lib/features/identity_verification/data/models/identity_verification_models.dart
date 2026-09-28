// Data-transfer models for the identity-verification feature.
//
// `IdentityVerificationSessionModel` mirrors the safe Laravel
// `IdentityVerificationResource` shape (reservation_id, status, attempts,
// latest_outcome, latest_score, decided_at, latest_decision). Storage paths,
// provider references and PII are absent there and here. The submit payloads
// mirror the documented multipart request fields — the image bytes themselves
// are handed to the transport layer, never modelled or logged.

import '../../domain/entities/identity_document.dart';
import '../../domain/entities/identity_document_check.dart';
import '../../domain/entities/identity_verification_request.dart';
import '../../domain/entities/identity_verification_session.dart';
import '../../domain/entities/identity_verification_status.dart';

typedef Json = Map<String, Object?>;

/// The multipart fields for `POST
/// /identity-verification/{reservation}/documents` (`document` binary +
/// optional `document_type`). The binary part is supplied separately by the
/// data source; this only carries the non-file fields.
class IdentityDocumentPayload {
  const IdentityDocumentPayload({required this.documentType});

  factory IdentityDocumentPayload.fromRequest(
    SubmitIdentityDocumentRequest r,
  ) =>
      IdentityDocumentPayload(documentType: r.type.wireValue);

  final String documentType;

  Json toFields() => <String, Object?>{'document_type': documentType};
}

/// Parsed `IdentityVerificationResource`.
class IdentityVerificationSessionModel {
  const IdentityVerificationSessionModel({
    required this.reservationId,
    required this.status,
    required this.attempts,
    required this.latestOutcome,
    this.decidedAt,
    this.documentCheck,
  });

  factory IdentityVerificationSessionModel.fromJson(Json json) {
    return IdentityVerificationSessionModel(
      reservationId: '${json['reservation_id']}',
      status: IdentityVerificationStatus.fromWire(
        (json['status'] as String?) ??
            IdentityVerificationStatus.notStarted.wireValue,
      ),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      latestOutcome: IdentityMatchOutcome.fromWire(
        json['latest_outcome'] as String?,
      ),
      decidedAt: _dateOrNull(json['decided_at']),
      documentCheck: _documentCheck(json['document_check']),
    );
  }

  /// `document_check` — status + reason/outcome codes only (no PII).
  static DocumentCheck? _documentCheck(Object? raw) {
    if (raw is! Map) return null;
    final Object? fields = raw['fields'];
    return DocumentCheck(
      status: DocumentCheckStatus.fromWire(raw['status'] as String?),
      reasons: <String>[
        for (final Object? r in (raw['reasons'] as List<Object?>?) ?? const <Object?>[])
          if (r is String) r,
      ],
      fields: <String, String>{
        if (fields is Map)
          for (final MapEntry<Object?, Object?> e in fields.entries)
            if (e.key is String && e.value is String) e.key! as String: e.value! as String,
      },
      canContinue: raw['can_continue'] == true,
      requiresNewDocument: raw['requires_new_document'] == true,
      uploadsRemaining: (raw['uploads_remaining'] as num?)?.toInt(),
    );
  }

  final String reservationId;
  final IdentityVerificationStatus status;
  final int attempts;
  final IdentityMatchOutcome latestOutcome;
  final DateTime? decidedAt;
  final DocumentCheck? documentCheck;

  IdentityVerificationSession toEntity() => IdentityVerificationSession(
        reservationId: reservationId,
        status: status,
        attempts: attempts,
        latestOutcome: latestOutcome,
        decidedAt: decidedAt,
        documentCheck: documentCheck,
      );

  static DateTime? _dateOrNull(Object? raw) {
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }
}

/// Describes an upload part without holding its bytes — used for logging-safe
/// diagnostics only.
class IdentityUploadDescriptor {
  const IdentityUploadDescriptor({required this.field, required this.image});

  final String field;
  final CapturedImage image;

  @override
  String toString() =>
      'IdentityUploadDescriptor($field: ${image.label}, ${image.sizeBytes}B)';
}
