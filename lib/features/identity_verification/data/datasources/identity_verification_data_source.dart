import '../../domain/entities/identity_document.dart';
import '../../domain/entities/identity_verification_request.dart';
import '../models/identity_verification_models.dart';

/// Upload progress, 0.0 → 1.0 (bytes sent / total). 1.0 means the bytes are
/// on the server — the backend is now running the OCR check.
typedef UploadProgress = void Function(double fraction);

/// The identity-verification data contract. Dummy + API implementations,
/// selected by DI (`AppConfig.useDummyData`) exactly like
/// `ReservationDataSource`. Methods return DTO models; the repository maps them
/// to domain entities.
abstract interface class IdentityVerificationDataSource {
  Future<IdentityVerificationSessionModel> fetchStatus(String reservationId);

  /// The document types the guest can choose and which sides to photograph.
  Future<List<IdentityDocumentOption>> documentTypes();

  Future<IdentityVerificationSessionModel> submitDocument(
    SubmitIdentityDocumentRequest request, {
    UploadProgress? onProgress,
  });

  Future<IdentityVerificationSessionModel> submitSelfie(
    SubmitSelfieRequest request, {
    UploadProgress? onProgress,
  });
}
