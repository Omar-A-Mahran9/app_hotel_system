import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/identity_verification_status.dart';
import '../identity_verification_l10n.dart';

/// Tonal chip for an [IdentityVerificationStatus], built on the design-system
/// [StatusPill]. Colour is derived from the status only — Laravel stays
/// authoritative for the status value itself.
class IdentityStatusPill extends StatelessWidget {
  const IdentityStatusPill({super.key, required this.status});

  final IdentityVerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppColorTokens c = context.colors;

    final (Color fg, Color bg) = switch (status) {
      IdentityVerificationStatus.staffRejected => (c.errorFg, c.errorBg),
      IdentityVerificationStatus.retryAllowed ||
      IdentityVerificationStatus.pendingManualReview ||
      IdentityVerificationStatus.notStarted =>
        (c.warningFg, c.warningBg),
      IdentityVerificationStatus.autoApproved ||
      IdentityVerificationStatus.staffApproved =>
        (c.successFg, c.successBg),
      _ => (c.infoFg, c.infoBg),
    };

    return StatusPill(
      label: l10n.identityStatusLabel(status),
      foreground: fg,
      background: bg,
      icon: Icons.circle,
    );
  }
}
