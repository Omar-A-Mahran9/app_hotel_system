import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../domain/entities/access_grant.dart';

/// `CHECKIN_DigitalKey` key card: `#0E0C0A`, radius 32, 28/24 padding —
/// "رقم الغرفة" (13, 70% white), the room number (64 bold), then
/// "انتهاء إقامتك · {date}" with the clock glyph (12, 70% white).
///
/// The room number is the front desk's assignment (`reservation.room`); the
/// backend's dummy/real provider credential (the PIN that opens the door) is
/// shown under it — the Figma frame omits it, but without it the key would
/// not open anything.
class AccessCredentialCard extends StatelessWidget {
  const AccessCredentialCard({
    super.key,
    required this.grant,
    this.roomNumber,
    this.stayEndsOn,
  });

  final AccessGrant grant;
  final String? roomNumber;

  /// The stay's check-out date (falls back to the credential expiry).
  final DateTime? stayEndsOn;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme text = Theme.of(context).textTheme;
    final MaterialLocalizations ml = MaterialLocalizations.of(context);
    final Color white = AppPrimitives.white;
    final Color muted = white.withValues(alpha: 0.7);
    final String? code = grant.visibleCredential;
    final String? shownRoomNumber = roomNumber ?? grant.roomNumber;
    final DateTime? endsOn = stayEndsOn ?? grant.expiresAt;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: const BoxDecoration(
        color: AppPrimitives.ink950,
        borderRadius: BorderRadius.all(Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.accessRoomNumberLabel,
            style: text.bodySmall?.copyWith(
              fontSize: 13,
              height: 20 / 13,
              fontWeight: FontWeight.w500,
              color: muted,
            ),
          ),
          Text(
            shownRoomNumber ?? l10n.accessRoomPending,
            style: shownRoomNumber == null
                ? text.titleLarge?.copyWith(color: white, height: 2)
                : text.displayLarge?.copyWith(
                    color: white,
                    fontSize: 64,
                    height: 80 / 64,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
          ),
          if (code != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(l10n.accessEntryCodeLabel, style: text.bodySmall?.copyWith(fontSize: 12, color: muted)),
            const SizedBox(height: 2),
            Text(
              code.split('').join(' '),
              key: const ValueKey<String>('access-credential'),
              style: text.headlineSmall?.copyWith(
                color: white,
                fontWeight: FontWeight.w700,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ],
          if (endsOn != null) ...<Widget>[
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Icon(AppIcons.time, size: 14, color: muted),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.accessStayEndsLabel(ml.formatShortMonthDay(endsOn)),
                    style: text.bodySmall?.copyWith(fontSize: 12, height: 18 / 12, color: muted),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
