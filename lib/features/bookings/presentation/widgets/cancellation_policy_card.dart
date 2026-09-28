import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../../core/localization/numerals.dart';

/// The "سياسة الإلغاء" card. With a [cancellation] it states this
/// reservation's snapshotted policy exactly as the backend decided it; without
/// one it states the platform rule ([freeCancellationHours] from the server).
class CancellationPolicyCard extends StatelessWidget {
  const CancellationPolicyCard({super.key, this.cancellation, this.freeCancellationHours});

  final CancellationState? cancellation;
  final int? freeCancellationHours;

  String _body(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final CancellationState? c = cancellation;
    if (c == null) return l10n.policyGeneral(freeCancellationHours ?? 0);
    if (c.allowed && c.freeUntil != null) {
      final MaterialLocalizations ml = MaterialLocalizations.of(context);
      final DateTime at = c.freeUntil!;
      return l10n.policyFreeUntil('${ml.formatMediumDate(at)} ${context.localDigits(ml.formatTimeOfDay(TimeOfDay.fromDateTime(at)))}');
    }
    return switch (c.reason) {
      'non_refundable_rate' => l10n.policyNonRefundable,
      'free_cancellation_window_closed' => l10n.policyWindowClosed,
      _ => c.refundable ? l10n.policyStayStarted : l10n.policyNonRefundable,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.l10n.bookingCancellationPolicyHeading,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(_body(context), style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
