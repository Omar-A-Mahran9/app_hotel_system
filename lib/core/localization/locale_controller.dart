import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'supported_locales.dart';

/// Holds the app locale.
///
/// Defaults to **Arabic** — the primary market locale and the Arabic-first
/// design intent — rather than following the device: a non-Arabic guest can
/// switch on the first-run language screen or from Account. `null` means "follow
/// the device locale" (resolved by `MaterialApp` against `supportedLocales`) and
/// is only reached via [useDeviceLocale].
///
/// Phase 0 keeps this in memory only; persistence is deferred with the rest of
/// the storage layer.
class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => SupportedLocales.arabic;

  void set(Locale? locale) => state = locale;

  void useDeviceLocale() => state = null;
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);
