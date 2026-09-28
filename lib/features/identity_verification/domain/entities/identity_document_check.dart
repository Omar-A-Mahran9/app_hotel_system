import 'package:flutter/foundation.dart';

/// Outcome of the backend's OCR document check, mirroring Laravel
/// `DocumentCheckStatus` (the `document_check.status` field of
/// `IdentityVerificationResource`).
enum DocumentCheckStatus {
  verified('verified'),
  needsReview('needs_review'),
  mismatch('mismatch'),
  ocrFailed('ocr_failed'),
  documentExpired('document_expired'),
  documentUnsupported('document_unsupported'),
  processing('processing'),
  unknown('unknown');

  const DocumentCheckStatus(this.wireValue);

  final String wireValue;

  static DocumentCheckStatus fromWire(String? value) {
    for (final DocumentCheckStatus s in DocumentCheckStatus.values) {
      if (s.wireValue == value) return s;
    }
    return DocumentCheckStatus.unknown;
  }
}

/// A per-field comparison outcome. Codes only — the backend never returns the
/// values it read or the ones the guest entered.
enum DocumentFieldOutcome { match, mismatch, unconfirmed, notChecked }

/// The OCR document check of the current attempt.
///
/// Laravel is authoritative: the app only reads [canContinue] /
/// [requiresNewDocument] to decide which screen to show and never decides a
/// verification itself.
@immutable
class DocumentCheck {
  const DocumentCheck({
    required this.status,
    this.reasons = const <String>[],
    this.fields = const <String, String>{},
    this.canContinue = false,
    this.requiresNewDocument = false,
    this.uploadsRemaining,
  });

  final DocumentCheckStatus status;
  final List<String> reasons;

  /// `name` / `number` / `birth` / `expiry` / `nationality` → outcome code.
  final Map<String, String> fields;
  final bool canContinue;
  final bool requiresNewDocument;
  final int? uploadsRemaining;

  DocumentFieldOutcome field(String name) => switch (fields[name]) {
        'match' || 'strong' || 'valid' => DocumentFieldOutcome.match,
        'mismatch' || 'expired' => DocumentFieldOutcome.mismatch,
        null || 'not_provided' => DocumentFieldOutcome.notChecked,
        _ => DocumentFieldOutcome.unconfirmed,
      };

  /// The guest-entered fields the document contradicts, in form order.
  List<String> get mismatchedFields => <String>['name', 'number', 'birth']
      .where((String f) => field(f) == DocumentFieldOutcome.mismatch)
      .toList(growable: false);

  @override
  bool operator ==(Object other) =>
      other is DocumentCheck &&
      other.status == status &&
      listEquals(other.reasons, reasons) &&
      mapEquals(other.fields, fields) &&
      other.canContinue == canContinue &&
      other.requiresNewDocument == requiresNewDocument &&
      other.uploadsRemaining == uploadsRemaining;

  @override
  int get hashCode => Object.hash(status, Object.hashAll(reasons),
      Object.hashAll(fields.entries.map((e) => '${e.key}=${e.value}')),
      canContinue, requiresNewDocument, uploadsRemaining);
}
