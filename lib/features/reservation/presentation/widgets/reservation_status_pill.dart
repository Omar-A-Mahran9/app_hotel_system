import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/reservation_status.dart';
import '../reservation_l10n.dart';

/// Tonal chip for a [ReservationStatus], built on the design-system
/// [StatusPill]. Colour is derived from the status only — Laravel stays
/// authoritative for the status value itself.
class ReservationStatusPill extends StatelessWidget {
  const ReservationStatusPill({super.key, required this.status});

  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppColorTokens c = context.colors;

    final (Color fg, Color bg) = switch (status) {
      ReservationStatus.cancelled ||
      ReservationStatus.checkoutBlocked =>
        (c.errorFg, c.errorBg),
      ReservationStatus.pending ||
      ReservationStatus.checkoutInProgress =>
        (c.warningFg, c.warningBg),
      ReservationStatus.checkedOut ||
      ReservationStatus.invoiced =>
        (c.infoFg, c.infoBg),
      _ => (c.successFg, c.successBg),
    };

    return StatusPill(
      label: l10n.reservationStatusLabel(status),
      foreground: fg,
      background: bg,
      icon: Icons.circle,
    );
  }
}
