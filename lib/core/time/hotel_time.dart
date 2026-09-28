import '../localization/generated/app_localizations.dart';

/// `"HH:MM"` (24h, as stored) → `3:00 مساءً` / `3:00 PM`; `null` when absent
/// or malformed. Shared by the hotel and room detail screens.
String? formatHotelTime(String? hhmm, AppLocalizations l10n) {
  if (hhmm == null) return null;
  final List<String> parts = hhmm.split(':');
  if (parts.length < 2) return null;
  final int? h = int.tryParse(parts[0]);
  final int? m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    return null;
  }
  final int h12 = h % 12 == 0 ? 12 : h % 12;
  final String time = '$h12:${m.toString().padLeft(2, '0')}';
  // 12:xx is midday — "ظهرًا" in Arabic, not the evening "مساءً".
  return l10n.hotelTimeOfDay(time, h < 12 ? 'am' : (h == 12 ? 'noon' : 'pm'));
}
