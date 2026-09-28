import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/result_view.dart';
import '../../domain/entities/identity_verification_session.dart';
import '../../domain/entities/identity_verification_status.dart';
import 'identity_status_pill.dart';

/// The safe outcome view for a resolved (or awaiting-review) session. Shown on
/// the verification page while navigating and on the dedicated result page.
/// Never renders provider detail, scores or document data.
class VerificationResultView extends StatelessWidget {
  const VerificationResultView({super.key, required this.session});

  final IdentityVerificationSession session;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);

    final (
      InfoBannerTone tone,
      String title,
      String body,
    ) = switch (session.status) {
      IdentityVerificationStatus.autoApproved ||
      IdentityVerificationStatus.staffApproved => (
        InfoBannerTone.success,
        l10n.identityApprovedTitle,
        l10n.identityApprovedBody,
      ),
      IdentityVerificationStatus.pendingManualReview => (
        InfoBannerTone.warning,
        l10n.identityManualReviewTitle,
        l10n.identityManualReviewBody,
      ),
      IdentityVerificationStatus.retryAllowed => (
        InfoBannerTone.warning,
        l10n.identityRetryTitle,
        l10n.identityRetryBody,
      ),
      IdentityVerificationStatus.staffRejected => (
        InfoBannerTone.error,
        l10n.identityRejectedTitle,
        session.canRetry
            ? l10n.identityRejectedRetryBody
            : l10n.identityRejectedBody,
      ),
      _ => (InfoBannerTone.info, l10n.identityVerificationTitle, ''),
    };

    return ResultView(
      tone: tone,
      title: title,
      message: body.isEmpty ? null : body,
      detail: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.reservationStatusFieldLabel,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              IdentityStatusPill(status: session.status),
            ],
          ),
          if (session.attempts > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.identityAttemptCount(session.attempts),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
