import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../reservation/domain/entities/reservation_status.dart';

/// The coarse booking-list status pill (`bookingStatus*`), shared by
/// [BookingCard] and the booking-detail summary card — deliberately coarser
/// than the full [ReservationStatus] (see `BookingCard`'s doc comment).
class BookingStatusPill extends StatelessWidget {
  const BookingStatusPill({super.key, required this.status});

  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppColorTokens c = context.colors;
    final (String label, Color fg, Color bg) = switch (status) {
      ReservationStatus.pending => (l10n.bookingStatusPending, c.warningFg, c.warningBg),
      ReservationStatus.depositHeld ||
      ReservationStatus.verified =>
        (l10n.bookingStatusConfirmed, c.successFg, c.successBg),
      ReservationStatus.checkedIn ||
      ReservationStatus.inStay ||
      ReservationStatus.checkoutInProgress ||
      ReservationStatus.checkoutBlocked =>
        (l10n.bookingStatusCheckedIn, c.successFg, c.successBg),
      ReservationStatus.checkedOut ||
      ReservationStatus.invoiced =>
        (l10n.bookingStatusCompleted, c.successFg, c.successBg),
      ReservationStatus.cancelled =>
        (l10n.bookingStatusCancelled, c.errorFg, c.errorBg),
    };
    return StatusPill(label: label, foreground: fg, background: bg, icon: AppIcons.check);
  }
}
