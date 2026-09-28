/// Fixed pixel sizes that are part of the design system but don't belong on the
/// spacing or radius scales — icon glyph sizes and a few component dimensions.
///
/// Widgets should read these instead of sprinkling magic numbers, so an icon
/// audit or a density change happens in one place. Sourced from the component
/// frames in `mobile/Design/Hotel Design System.fig`.
abstract final class AppIconSizes {
  /// Inline icon inside a button label.
  static const double button = 18;

  /// Leading icon inside a status pill / small chip.
  static const double pill = 14;

  /// Small inline icon (info-banner glyph, dense affordances).
  static const double iconSm = 16;

  /// Default UI icon (info-banner glyph at full size, list trailing).
  static const double icon = 18;

  /// Icon inside a tinted badge circle (info-banner / result header).
  static const double badge = 28;

  /// Icon inside a dense tinted badge circle.
  static const double badgeDense = 24;

  /// Bottom-navigation destination icon.
  static const double nav = 24;

  /// App-bar action / leading icon.
  static const double appBar = 24;
}

/// Component-level fixed dimensions.
abstract final class AppSizes {
  /// The rounded-square icon tile on empty / message / result views.
  static const double emptyStateTile = 72;

  /// Icon-button hit target (Figma `Icon Button` = 44×44).
  static const double iconButton = 44;

  /// Button heights — Figma `Button` component, `Size` axis.
  static const double buttonSmall = 40;
  static const double buttonMedium = 48;
  static const double buttonLarge = 56;
}
