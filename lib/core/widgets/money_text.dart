import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Centralised currency presentation.
///
/// The Figma renders money as **⟨Saudi Riyal mark⟩ + amount** (e.g. `450 ﷼`),
/// not the sentence form `SAR 450`. The Saudi Riyal symbol has no reliable
/// cross-platform glyph, so it is drawn as a small vector ([RiyalMark]) sized to
/// the surrounding text — traced from the official symbol's path data, so it
/// stays crisp at every size and in both themes.
///
/// This is presentation only. It never rounds, converts, or invents a rate —
/// [amount] is whatever the backend returned, in [currency] (the ISO code the
/// response / reservation snapshot carries). The drawn mark is used only for
/// SAR; any other currency prints its code.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.style,
    this.color,
    this.markSize,
    this.semanticsLabel,
    this.suffix,
    this.currency,
  });

  /// The drawn [RiyalMark] currency.
  static const String riyal = 'SAR';

  /// The amount in whole Saudi Riyals, exactly as the backend provides it.
  final num amount;

  /// Overrides the default number style ([AppTypography.numMd]).
  final TextStyle? style;

  /// Overrides both the text and mark colour.
  final Color? color;

  /// Mark height; defaults to the resolved font size.
  final double? markSize;

  final String? semanticsLabel;

  /// Optional trailing label in a muted style — e.g. "/ night", "total".
  final String? suffix;

  /// ISO currency code of [amount]; `null` = the backend's booking currency
  /// was not in this payload (treated as [riyal]).
  final String? currency;

  bool get _isRiyal => currency == null || currency!.toUpperCase() == riyal;

  static String _digits(BuildContext context, num value) {
    // Group thousands with a comma; keep Western digits (the app's `intl` CLDR
    // data formats `ar` with Western digits too, so prices stay consistent
    // with other numeric UI). Digit *shape* localisation, if wanted, belongs
    // in one place later.
    // Whole amounts print without decimals ("945"); fractional ones always
    // with two ("93.20"), as the backend stores them.
    final String raw = value == value.truncate()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
    final List<String> parts = raw.split('.');
    final String intPart = parts.first;
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) out.write(',');
      out.write(intPart[i]);
    }
    if (parts.length > 1) out.write('.${parts[1]}');
    return out.toString();
  }

  /// Plain-text form for places that need a `String` (tooltips, semantics,
  /// `SnackBar`s), where the drawn [RiyalMark] can't be used: `"SAR 945"`.
  static String plain(BuildContext context, num amount, {String? currency}) =>
      '${currency ?? riyal} ${_digits(context, amount)}';

  /// The formatted digits alone — for localized strings that place the
  /// amount themselves (`moneyAmount`).
  static String digits(BuildContext context, num amount) => _digits(context, amount);

  @override
  Widget build(BuildContext context) {
    final TextStyle resolved =
        (style ?? AppTypography.numMd(_defaultColor(context))).copyWith(
          color: color,
        );
    final double size = markSize ?? resolved.fontSize ?? 17;
    final Color markColor = color ?? resolved.color ?? _defaultColor(context);
    final String text = _digits(context, amount);

    final TextStyle numberStyle = resolved.copyWith(
      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
    );
    final Color muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Semantics(
      label: semanticsLabel ??
          '${currency ?? riyal} $text${suffix == null ? '' : ' $suffix'}',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(text, style: numberStyle),
            const SizedBox(width: AppSpacing.space1),
            if (_isRiyal)
              RiyalMark(size: size * 0.92, color: markColor)
            else
              Text(currency!.toUpperCase(), style: numberStyle.copyWith(color: markColor)),
            if (suffix != null) ...<Widget>[
              const SizedBox(width: AppSpacing.space1),
              Text(
                suffix!,
                style: (style ?? numberStyle).copyWith(
                  color: muted,
                  fontWeight: AppTypography.regular,
                  fontSize: (resolved.fontSize ?? 17) * 0.82,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // The rendered Figma prices are the warm near-black brown (`#513425`), not
  // gold — gold is reserved for ratings. Callers on dark/accent surfaces pass an
  // explicit [color].
  Color _defaultColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
}

/// The official Saudi Riyal currency mark, drawn to [size] (roughly a
/// capital-letter height). Traced from the official symbol's source path
/// (16×18 units) so the shape matches the sanctioned mark exactly, rather
/// than approximating it with strokes.
class RiyalMark extends StatelessWidget {
  const RiyalMark({super.key, this.size = 16, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? context.colors.accentWarmFg;
    return CustomPaint(
      // Natural aspect ratio of the source path's 16×18 viewBox.
      size: Size(size * 16 / 18, size),
      painter: _RiyalPainter(c),
    );
  }
}

class _RiyalPainter extends CustomPainter {
  const _RiyalPainter(this.color);

  final Color color;

  // Official Saudi Riyal symbol, in its native 16×18 coordinate space.
  static final Path _path = Path()
    ..moveTo(15.5, 14.6084)
    ..cubicTo(15.3943, 15.4635, 15.348, 15.8345, 14.9531, 16.668)
    ..lineTo(8.88965, 17.9199)
    ..cubicTo(9.02903, 17.0191, 9.21461, 16.324, 9.5166, 15.9072)
    ..lineTo(15.5, 14.6084)
    ..close()
    ..moveTo(7.05469, 8.71191)
    ..lineTo(8.86621, 8.31934)
    ..lineTo(8.86621, 2.59375)
    ..cubicTo(9.54134, 1.8359, 9.95656, 1.49559, 10.7715, 1.06543)
    ..lineTo(10.7715, 7.90527)
    ..lineTo(15.5, 6.87891)
    ..cubicTo(15.3943, 7.73376, 15.3478, 8.10429, 14.9531, 8.9375)
    ..lineTo(10.7715, 9.82129)
    ..lineTo(10.7715, 11.7451)
    ..lineTo(15.5, 10.7441)
    ..cubicTo(15.3943, 11.5992, 15.348, 11.9702, 14.9531, 12.8037)
    ..lineTo(10.7715, 13.667)
    ..lineTo(10.7715, 13.6846)
    ..lineTo(8.86621, 14.0781)
    ..lineTo(8.86621, 10.2236)
    ..lineTo(7.05469, 10.6064)
    ..lineTo(7.05469, 13.0361)
    ..lineTo(7.02344, 13.042)
    ..cubicTo(6.60672, 13.7727, 6.01827, 14.6506, 5.45117, 15.3516)
    ..lineTo(-0.5, 16.4854)
    ..cubicTo(-0.446639, 15.7196, -0.335521, 15.2879, 0.0107422, 14.5166)
    ..lineTo(5.14941, 13.4023)
    ..lineTo(5.14941, 11.0098)
    ..lineTo(0.386719, 12.0176)
    ..cubicTo(0.440076, 11.2519, 0.552243, 10.821, 0.898438, 10.0498)
    ..lineTo(5.14941, 9.12598)
    ..lineTo(5.14941, 1.52832)
    ..cubicTo(5.82454, 0.770471, 6.23977, 0.430158, 7.05469, 0)
    ..lineTo(7.05469, 8.71191)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.scale(size.width / 16, size.height / 18);
    canvas.drawPath(_path, fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RiyalPainter oldDelegate) => oldDelegate.color != color;
}
