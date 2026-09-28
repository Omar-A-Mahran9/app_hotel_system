import 'package:flutter/widgets.dart';

/// The locales the Guest App ships. Arabic is listed first because it is the
/// primary market locale; [resolveLocale] still honours the device preference.
abstract final class SupportedLocales {
  static const Locale arabic = Locale('ar');
  static const Locale english = Locale('en');

  static const List<Locale> all = <Locale>[arabic, english];

  static bool isRtl(Locale locale) => locale.languageCode == 'ar';

  /// Chooses a supported locale for a device preference list. Arabic is the
  /// primary market locale, so it is also the fallback when the device
  /// preference matches nothing the app ships (the guest can still switch on the
  /// first-run language screen or from Account).
  static Locale resolveLocale(
    Locale? deviceLocale,
    Iterable<Locale> supported,
  ) {
    if (deviceLocale == null) return arabic;
    for (final Locale locale in supported) {
      if (locale.languageCode == deviceLocale.languageCode) return locale;
    }
    return arabic;
  }
}
