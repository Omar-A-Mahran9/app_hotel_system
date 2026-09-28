import '../../../core/localization/l10n.dart';
import '../domain/entities/identity_document.dart';
import '../domain/entities/identity_verification_status.dart';

/// Localized labels for the identity-verification feature's enums. Keeps the
/// enum → string mapping in one place, mirroring `ReservationL10n`.
extension IdentityVerificationL10n on AppLocalizations {
  String identityStatusLabel(IdentityVerificationStatus status) =>
      switch (status) {
        IdentityVerificationStatus.notStarted => identityStatusNotStarted,
        IdentityVerificationStatus.documentUploaded =>
          identityStatusDocumentUploaded,
        IdentityVerificationStatus.selfieCaptured =>
          identityStatusSelfieCaptured,
        IdentityVerificationStatus.matchingInProgress =>
          identityStatusMatchingInProgress,
        IdentityVerificationStatus.autoApproved => identityStatusAutoApproved,
        IdentityVerificationStatus.pendingManualReview =>
          identityStatusPendingManualReview,
        IdentityVerificationStatus.staffApproved => identityStatusStaffApproved,
        IdentityVerificationStatus.staffRejected => identityStatusStaffRejected,
        IdentityVerificationStatus.retryAllowed => identityStatusRetryAllowed,
      };

  String identityDocumentTypeLabelFor(IdentityDocumentType type) =>
      switch (type) {
        IdentityDocumentType.passport => identityDocumentTypePassport,
        IdentityDocumentType.egyptianNationalId => identityDocumentTypeEgyptianId,
        IdentityDocumentType.saudiNationalId => identityDocumentTypeSaudiId,
        IdentityDocumentType.saudiIqama => identityDocumentTypeSaudiIqama,
      };

  /// "Front only" / "front and back" / "back optional" for a type.
  String identityDocumentSidesLabel(BackImagePolicy back) => switch (back) {
        BackImagePolicy.none => identityDocumentSidesFrontOnly,
        BackImagePolicy.optional => identityDocumentSidesBackOptional,
        BackImagePolicy.required => identityDocumentSidesFrontAndBack,
      };
}
