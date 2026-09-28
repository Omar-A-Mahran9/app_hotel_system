import '../../../core/localization/l10n.dart';
import '../domain/entities/access_status.dart';

/// Localized labels for the digital-access feature's enum. One place for the
/// enum → string mapping, mirroring `ReservationL10n`.
extension DigitalAccessL10n on AppLocalizations {
  String accessStatusLabel(AccessStatus status) => switch (status) {
        AccessStatus.notIssued => accessStatusNotIssued,
        AccessStatus.issueRequested => accessStatusIssueRequested,
        AccessStatus.active => accessStatusActive,
        AccessStatus.failed => accessStatusFailed,
        AccessStatus.revokeRequested => accessStatusRevokeRequested,
        AccessStatus.revoked => accessStatusRevoked,
        AccessStatus.expired => accessStatusExpired,
      };
}
