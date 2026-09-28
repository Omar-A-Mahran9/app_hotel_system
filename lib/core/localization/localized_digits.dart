import 'package:flutter/widgets.dart';

/// Renders an integer with the digit shapes the active locale expects.
///
/// The app's `intl`/CLDR data formats `ar` numbers with Western digits by
/// default, whereas Flutter's Material *date* formatting uses Arabic-Indic
/// digits. Screens that place their own numbers next to Material-formatted
/// dates — the stay-date calendar in particular — use this so the two agree.
///
/// This does **not** add grouping separators; it is only a digit transliteration
/// for short values (day numbers, small counts).
String localizedDigits(int value, Locale locale) {
  final String western = value.toString();
  if (locale.languageCode != 'ar') return western;

  const List<String> arabicIndic = <String>[
    '٠', '١', '٢', '٣', '٤',
    '٥', '٦', '٧', '٨', '٩',
  ];
  final StringBuffer out = StringBuffer();
  for (final int unit in western.codeUnits) {
    if (unit >= 0x30 && unit <= 0x39) {
      out.write(arabicIndic[unit - 0x30]);
    } else {
      out.writeCharCode(unit);
    }
  }
  return out.toString();
}

extension LocalizedDigitsX on BuildContext {
  /// `context.digits(6)` → `"6"` (en) / `"٦"` (ar).
  String digits(int value) => localizedDigits(value, Localizations.localeOf(this));
}
