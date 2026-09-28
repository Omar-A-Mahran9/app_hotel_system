import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_controller.dart';
import 'supported_locales.dart';

/// The language code the backend should localize content into (`ar` / `en`).
///
/// Laravel resolves every guest-facing string (hotel name, tagline, room
/// names, highlights, facilities…) to ONE language per request from the
/// `X-Locale` header, so the API client sends this on every call. It mirrors
/// what `MaterialApp` shows: the chosen locale, or — when following the
/// device — the same resolution [SupportedLocales.resolveLocale] applies.
///
/// Providers that hold server content `ref.watch` this so a language switch
/// refetches them instead of leaving the previous language on screen.
final contentLanguageProvider = Provider<String>((Ref ref) {
  final Locale? chosen = ref.watch(localeControllerProvider);
  final Locale effective = chosen ??
      SupportedLocales.resolveLocale(
        PlatformDispatcher.instance.locale,
        SupportedLocales.all,
      );
  return effective.languageCode;
});
