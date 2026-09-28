import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/theme/app_colors.dart';
import 'package:hotel_guest_app/core/theme/app_theme.dart';

void main() {
  test('light and dark themes are Material 3 and carry semantic colours', () {
    final ThemeData light = AppTheme.light;
    final ThemeData dark = AppTheme.dark;

    expect(light.useMaterial3, isTrue);
    expect(dark.useMaterial3, isTrue);
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);

    expect(light.extension<AppSemanticColors>(), isNotNull);
    expect(dark.extension<AppSemanticColors>(), isNotNull);

    // The design-system token set is registered for both modes …
    expect(light.extension<AppColorTokens>(), isNotNull);
    expect(dark.extension<AppColorTokens>(), isNotNull);
    // … and the dark theme is the real one from the Figma, not a guess.
    expect(dark.colorScheme.surface, const Color(0xFF1D1A16));
  });

  test('light theme follows the v2 neutral black/white palette', () {
    final ThemeData light = AppTheme.light;
    final AppColorTokens c = light.extension<AppColorTokens>()!;

    expect(light.colorScheme.primary, const Color(0xFF0E0C0A)); // ink/950
    expect(light.scaffoldBackgroundColor, const Color(0xFFFFFFFF)); // stone/0
    expect(c.bgPrimaryPressed, const Color(0xFF171412)); // ink/900
    expect(c.bgInverse, const Color(0xFF171412)); // ink/900
    expect(c.textPrimary, const Color(0xFF110F0C)); // stone/950
    expect(c.textAccent, const Color(0xFF38312B)); // ink/700
    expect(c.accentWarmBg, const Color(0xFFFAF7F0)); // gold/25
  });

  test('button and input theming is centralised', () {
    final ThemeData light = AppTheme.light;
    expect(light.filledButtonTheme.style, isNotNull);
    expect(light.outlinedButtonTheme.style, isNotNull);
    expect(light.inputDecorationTheme.filled, isTrue);
  });
}
