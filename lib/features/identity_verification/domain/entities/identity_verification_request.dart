import 'package:flutter/foundation.dart';

import 'identity_document.dart';

/// Submit-an-ID-document request.
///
/// The approved guest-facing backend `POST
/// /api/v1/guest/reservations/{reservation}/identity/documents`
/// (`GuestIdentityVerificationController::documents`, reusing the same
/// `SubmitIdentityDocumentRequest`/`IdentityVerificationService` as the
/// staff-scoped `POST /api/v1/identity-verification/{reservation}/documents`)
/// takes a `document` file (jpg/png/pdf) and an optional short `document_type`
/// label, ownership-checked against the calling guest. This request only
/// carries what the guest app has: the reservation, the chosen [type] and a
/// locally captured [image] referenced by non-sensitive metadata only.
@immutable
class SubmitIdentityDocumentRequest {
  const SubmitIdentityDocumentRequest({
    required this.reservationId,
    required this.type,
    required this.image,
    this.backImage,
    this.claim,
  });

  final String reservationId;
  final IdentityDocumentType type;

  /// The front (or passport details page).
  final CapturedImage image;

  /// The back of the card, when the document type needs / allows it.
  final CapturedImage? backImage;

  /// What the guest says is on the document — compared server-side with the
  /// OCR result. Required by the guest endpoint.
  final IdentityDocumentClaim? claim;

  /// A stable key for local duplicate-submit dedupe. No time / randomness.
  String get idempotencyKey =>
      'idv-doc:$reservationId:${type.wireValue}';

  @override
  bool operator ==(Object other) =>
      other is SubmitIdentityDocumentRequest &&
      other.reservationId == reservationId &&
      other.type == type &&
      other.image == image &&
      other.backImage == backImage &&
      other.claim == claim;

  @override
  int get hashCode => Object.hash(reservationId, type, image, backImage, claim);
}

/// Submit-a-selfie request.
///
/// The approved guest-facing backend `POST
/// /api/v1/guest/reservations/{reservation}/identity/selfie`
/// (`GuestIdentityVerificationController::selfie`, reusing
/// `SubmitIdentitySelfieRequest`) takes a `selfie` image and an
/// `Idempotency-Key` HTTP header. Same guest/staff dual-endpoint shape as
/// [SubmitIdentityDocumentRequest].
@immutable
class SubmitSelfieRequest {
  const SubmitSelfieRequest({
    required this.reservationId,
    required this.image,
  });

  final String reservationId;
  final CapturedImage image;

  /// Used as the `Idempotency-Key` header and for local dedupe of the *current*
  /// attempt. Stable across widget rebuilds; a genuine retry re-runs because
  /// the data source only caches non-retryable outcomes.
  String get idempotencyKey => 'idv-selfie:$reservationId';

  @override
  bool operator ==(Object other) =>
      other is SubmitSelfieRequest &&
      other.reservationId == reservationId &&
      other.image == image;

  @override
  int get hashCode => Object.hash(reservationId, image);
}
