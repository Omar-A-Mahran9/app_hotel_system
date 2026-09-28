import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../domain/entities/service_order_status.dart';
import '../stay_services_l10n.dart';

/// Tonal chip for a [ServiceOrderStatus], built on the design-system
/// [StatusPill]. Colour is derived from the status only.
class ServiceOrderStatusPill extends StatelessWidget {
  const ServiceOrderStatusPill({super.key, required this.status});

  final ServiceOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppColorTokens c = context.colors;

    final (Color fg, Color bg) = switch (status) {
      ServiceOrderStatus.cancelled => (c.errorFg, c.errorBg),
      ServiceOrderStatus.requested => (c.warningFg, c.warningBg),
      ServiceOrderStatus.confirmed => (c.infoFg, c.infoBg),
      ServiceOrderStatus.fulfilled => (c.successFg, c.successBg),
    };

    return StatusPill(
      label: l10n.serviceOrderStatusLabel(status),
      foreground: fg,
      background: bg,
      icon: Icons.circle,
    );
  }
}
