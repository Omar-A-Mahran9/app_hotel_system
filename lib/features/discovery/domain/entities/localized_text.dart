import 'package:flutter/widgets.dart';

/// A short piece of content that exists in both supported locales.
///
/// Hotel and room names, taglines and bed descriptions come from the backend
/// already localized in a later phase; until then the dummy dataset carries both
/// strings and widgets resolve against the active [Locale]. Keeping this a value
/// object (rather than a bare `Map`) means the presentation layer never guesses
/// a key.
@immutable
class LocalizedText {
  const LocalizedText({required this.ar, required this.en});

  final String ar;
  final String en;

  /// Picks the string for [locale]; anything that is not Arabic falls back to
  /// English, matching [SupportedLocales.resolveLocale].
  String resolve(Locale locale) => locale.languageCode == 'ar' ? ar : en;

  @override
  bool operator ==(Object other) =>
      other is LocalizedText && other.ar == ar && other.en == en;

  @override
  int get hashCode => Object.hash(ar, en);

  @override
  String toString() => 'LocalizedText(en: $en)';
}
