import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/payment_status.dart';
import '../payment_l10n.dart';

/// Tonal chip for a [PaymentStatus], built on the design-system [StatusPill].
/// Colour is derived from the status only — Laravel stays authoritative for the
/// status value itself.
class PaymentStatusPill extends StatelessWidget {
  const PaymentStatusPill({super.key, required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppColorTokens c = context.colors;

    final (Color fg, Color bg) = switch (status) {
      PaymentStatus.holdFailed ||
      PaymentStatus.captureFailed ||
      PaymentStatus.settlementFailed ||
      PaymentStatus.refundFailed ||
      PaymentStatus.cancelled ||
      PaymentStatus.expired =>
        (c.errorFg, c.errorBg),
      PaymentStatus.notStarted ||
      PaymentStatus.holdRequested ||
      PaymentStatus.captureRequested ||
      PaymentStatus.finalSettlementRequested ||
      PaymentStatus.refundRequested =>
        (c.warningFg, c.warningBg),
      PaymentStatus.refunded =>
        (c.infoFg, c.infoBg),
      _ => (c.successFg, c.successBg),
    };

    return StatusPill(
      label: l10n.paymentStatusLabel(status),
      foreground: fg,
      background: bg,
      icon: Icons.circle,
    );
  }
}
