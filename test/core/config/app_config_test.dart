import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/config/app_config.dart';

void main() {
  // No `--dart-define=API_BASE_URL` is set while running `flutter test`, so
  // `AppConfig.fromEnvironment()` always falls back to the per-platform dev
  // default under test — exactly the branch this guards.
  group('AppConfig.fromEnvironment platform default (no API_BASE_URL override)', () {
    final TargetPlatform? original = debugDefaultTargetPlatformOverride;

    tearDown(() {
      debugDefaultTargetPlatformOverride = original;
    });

    test('Android gets the emulator-to-host loopback alias, not localhost', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final config = AppConfig.fromEnvironment();

      expect(config.apiBaseUrl, 'http://10.0.2.2:8000');
    });

    test('iOS gets the real loopback — 10.0.2.2 is meaningless off the Android emulator', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final config = AppConfig.fromEnvironment();

      expect(config.apiBaseUrl, 'http://127.0.0.1:8000');
    });
  });
}
