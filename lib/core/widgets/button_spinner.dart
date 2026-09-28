import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';

/// The in-button loading spinner — a 20px `CircularProgressIndicator` at
/// `strokeWidth: 2`, tinted to the button's foreground. Shared by
/// [PrimaryButton] / [SecondaryButton] / [DangerButton] so the `Loading` state
/// looks identical across the Button component's variants.
class ButtonSpinner extends StatelessWidget {
  const ButtonSpinner({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
}

/// The Figma `Button` component's `Size` axis — Small 40 / Medium 48 / Large 56.
/// `medium` is the default; full-width standing CTAs use the theme's 52.
enum AppButtonSize {
  small(AppSizes.buttonSmall),
  medium(AppSizes.buttonMedium),
  large(AppSizes.buttonLarge);

  const AppButtonSize(this.height);

  /// Minimum button height in logical pixels.
  final double height;
}
