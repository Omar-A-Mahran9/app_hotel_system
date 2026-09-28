import 'package:flutter/foundation.dart';

import 'identity_document_check.dart';
import 'identity_verification_status.dart';

/// A safe, coarse classification of the automated match result, mirroring the
/// backend `latest_outcome` string on `IdentityVerificationResource`.
///
/// The backend sets this field verbatim from its provider-boundary
/// `MatchOutcome` enum (`App\Domain\IdentityVerification\Provider\MatchOutcome`):
/// `high_match` / `medium_match` / `low_match` / `error`. [documentUnclear]
/// (wire `error`) means the provider could not read the document at all (a
/// hard capture/read failure); [faceNotMatched] (wire `low_match`) means the
/// document was read but the selfie did not match it with enough confidence.
/// Never carries a score breakdown or any provider detail.
enum IdentityMatchOutcome {
  match,
  faceNotMatched,
  documentUnclear,
  inconclusive,
  unknown;

  static IdentityMatchOutcome fromWire(String? value) => switch (value) {
        'high_match' || 'medium_match' || 'match' || 'approved' || 'pass' =>
          IdentityMatchOutcome.match,
        'low_match' || 'no_match' || 'mismatch' || 'fail' =>
          IdentityMatchOutcome.faceNotMatched,
        'error' => IdentityMatchOutcome.documentUnclear,
        'inconclusive' || 'manual' || 'review' => IdentityMatchOutcome.inconclusive,
        _ => IdentityMatchOutcome.unknown,
      };
}

/// An identity-verification session as the guest app knows it.
///
/// Mirrors the safe fields of the Laravel `IdentityVerificationResource`
/// (`reservation_id`, `status`, `attempts`, `latest_outcome`, `decided_at`).
/// Document/selfie storage paths, provider references, raw scores, attempt
/// metadata and PII are deliberately absent there and here
/// (mobile/docs/architecture.md §8).
///
/// Laravel stays authoritative for [status]; the app never transitions a
/// session itself.
@immutable
class IdentityVerificationSession {
  const IdentityVerificationSession({
    required this.reservationId,
    required this.status,
    this.attempts = 0,
    this.latestOutcome = IdentityMatchOutcome.unknown,
    this.decidedAt,
    this.documentCheck,
  });

  /// A "nothing submitted yet" session for a reservation.
  factory IdentityVerificationSession.notStarted(String reservationId) =>
      IdentityVerificationSession(
        reservationId: reservationId,
        status: IdentityVerificationStatus.notStarted,
      );

  final String reservationId;
  final IdentityVerificationStatus status;
  final int attempts;
  final IdentityMatchOutcome latestOutcome;
  final DateTime? decidedAt;

  /// The OCR check of the current attempt's document (null before any upload,
  /// or for an attempt that predates OCR).
  final DocumentCheck? documentCheck;

  /// The document was uploaded but the OCR check rejected it (mismatch,
  /// unreadable, expired, unsupported) — the guest must fix their details or
  /// upload another document before the selfie step.
  bool get documentRejected =>
      status == IdentityVerificationStatus.documentUploaded &&
      (documentCheck?.requiresNewDocument ?? false);

  bool get isApproved => status.isApproved;
  bool get isManualReview => status.isManualReview;
  bool get isProcessing => status.isProcessing;
  bool get needsDocument => status.needsDocument;
  bool get needsSelfie =>
      status.needsSelfie && (documentCheck == null || documentCheck!.canContinue);

  /// Retry eligibility, as far as the app can tell — the state machine allows
  /// it and the backend has not said otherwise.
  bool get canRetry => status.allowsRetry;

  /// A resolved session that will not change without a new guest action
  /// (approved, or awaiting a staff decision).
  bool get isResolved => status.isApproved || status.isManualReview;

  IdentityVerificationSession copyWith({
    IdentityVerificationStatus? status,
    int? attempts,
    IdentityMatchOutcome? latestOutcome,
    DateTime? decidedAt,
    DocumentCheck? documentCheck,
  }) {
    return IdentityVerificationSession(
      reservationId: reservationId,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      latestOutcome: latestOutcome ?? this.latestOutcome,
      decidedAt: decidedAt ?? this.decidedAt,
      documentCheck: documentCheck ?? this.documentCheck,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is IdentityVerificationSession &&
      other.reservationId == reservationId &&
      other.status == status &&
      other.attempts == attempts &&
      other.latestOutcome == latestOutcome &&
      other.decidedAt == decidedAt &&
      other.documentCheck == documentCheck;

  @override
  int get hashCode => Object.hash(
      reservationId, status, attempts, latestOutcome, decidedAt, documentCheck);

  @override
  String toString() =>
      'IdentityVerificationSession($reservationId, ${status.wireValue}, '
      'attempts: $attempts)';
}
