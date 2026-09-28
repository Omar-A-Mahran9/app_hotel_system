import '../entities/identity_document.dart';
import '../entities/identity_verification_request.dart';
import '../entities/identity_verification_session.dart';

/// The identity-verification contract the presentation layer depends on
/// (mobile/docs/architecture.md §4). Which data source fulfils it (dummy vs the
/// future guest API) is a DI decision, exactly as in `ReservationRepository`.
///
/// Every method throws a `Failure` on error (mapped by the implementation) so
/// callers only handle the user-safe type. No method returns document/selfie
/// contents, provider detail or raw scores.
abstract interface class IdentityVerificationRepository {
  /// The current session for a reservation. Returns a
  /// [IdentityVerificationStatus.notStarted] session when none exists yet.
  Future<IdentityVerificationSession> statusFor(String reservationId);

  /// The selectable document types (and their front/back requirement).
  Future<List<IdentityDocumentOption>> documentTypes();

  /// Uploads an ID document and returns the updated session.
  ///
  /// The backend runs the OCR document check synchronously; the returned
  /// session carries its outcome in `documentCheck`. [onProgress] reports the
  /// upload fraction (0..1).
  Future<IdentityVerificationSession> submitDocument(
    SubmitIdentityDocumentRequest request, {
    void Function(double fraction)? onProgress,
  });

  /// Uploads the selfie, runs the match server-side and returns the resolved
  /// session. Never manufactures an approval locally.
  ///
  /// A retry after `RETRY_ALLOWED` / `STAFF_REJECTED` is not a separate call:
  /// the guest re-enters [submitDocument] from that state (the approved
  /// `RETRY_ALLOWED → DOCUMENT_UPLOADED` / `STAFF_REJECTED → DOCUMENT_UPLOADED`
  /// edges), then [submitSelfie] again.
  Future<IdentityVerificationSession> submitSelfie(
    SubmitSelfieRequest request, {
    void Function(double fraction)? onProgress,
  });
}
