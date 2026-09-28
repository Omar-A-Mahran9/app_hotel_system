import 'package:flutter/material.dart';

/// The language-sheet header glyph — a globe with two speech bubbles (文 / A).
///
/// The **exact** v2 Figma artwork (`sheet / lan 1`, 33×33), decoded from the
/// `.fig` vector network into [Path]s, like [BrandMark]. A one-off
/// illustration, not part of the Iconsax set, so it lives with its only screen.
class LanguageGlyph extends StatelessWidget {
  const LanguageGlyph({super.key, this.size = 33, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _LanguageGlyphPainter(color),
    );
  }
}

class _LanguageGlyphPainter extends CustomPainter {
  const _LanguageGlyphPainter(this.color);

  final Color color;

  /// The Figma frame the paths are authored in.
  static const double _box = 33;

  static final List<Path> _paths = <Path>[
    Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(7.07, 19.63)
      ..cubicTo(6.92, 19.63, 6.77, 19.55, 6.69, 19.41)
      ..cubicTo(4.25, 15.5, 4.34, 10.52, 6.93, 6.71)
      ..lineTo(6.94, 6.71)
      ..cubicTo(6.95, 6.69, 6.96, 6.67, 6.98, 6.65)
      ..cubicTo(6.99, 6.63, 7.01, 6.61, 7.02, 6.58)
      ..cubicTo(9.17, 3.51, 12.7, 1.67, 16.45, 1.65)
      ..lineTo(16.58, 1.65)
      ..cubicTo(20.33, 1.67, 23.85, 3.51, 26, 6.58)
      ..cubicTo(26.03, 6.61, 26.06, 6.65, 26.07, 6.68)
      ..cubicTo(26.08, 6.69, 26.09, 6.71, 26.1, 6.71)
      ..lineTo(26.11, 6.72)
      ..cubicTo(27.92, 9.4, 28.55, 12.74, 27.81, 15.9)
      ..cubicTo(27.75, 16.14, 27.51, 16.29, 27.26, 16.23)
      ..cubicTo(27.02, 16.17, 26.87, 15.93, 26.93, 15.69)
      ..cubicTo(27.61, 12.78, 27.04, 9.7, 25.36, 7.23)
      ..cubicTo(25.35, 7.21, 25.33, 7.19, 25.32, 7.17)
      ..cubicTo(25.31, 7.16, 25.31, 7.14, 25.29, 7.14)
      ..cubicTo(25.29, 7.13, 25.28, 7.12, 25.27, 7.11)
      ..cubicTo(23.29, 4.27, 20.03, 2.57, 16.57, 2.56)
      ..lineTo(16.45, 2.56)
      ..cubicTo(12.99, 2.58, 9.74, 4.27, 7.76, 7.1)
      ..cubicTo(7.75, 7.12, 7.73, 7.14, 7.72, 7.16)
      ..cubicTo(7.71, 7.18, 7.69, 7.2, 7.67, 7.23)
      ..cubicTo(5.29, 10.74, 5.2, 15.33, 7.45, 18.94)
      ..cubicTo(7.59, 19.15, 7.52, 19.43, 7.31, 19.56)
      ..cubicTo(7.24, 19.61, 7.15, 19.63, 7.07, 19.63)
      ..close(),
    Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(12.54, 19.54)
      ..cubicTo(12.34, 19.54, 12.15, 19.4, 12.1, 19.2)
      ..cubicTo(12.01, 18.83, 11.93, 18.47, 11.85, 18.1)
      ..cubicTo(11.54, 16.49, 11.39, 14.86, 11.4, 13.24)
      ..cubicTo(11.39, 11.63, 11.54, 10, 11.85, 8.4)
      ..cubicTo(11.97, 7.81, 12.09, 7.3, 12.23, 6.84)
      ..cubicTo(13.15, 3.6, 14.69, 1.7, 16.44, 1.65)
      ..cubicTo(16.45, 1.65, 16.45, 1.65, 16.45, 1.65)
      ..lineTo(16.58, 1.65)
      ..cubicTo(16.59, 1.65, 16.59, 1.65, 16.6, 1.65)
      ..cubicTo(18.35, 1.7, 19.88, 3.6, 20.81, 6.85)
      ..cubicTo(20.94, 7.3, 21.06, 7.82, 21.18, 8.4)
      ..cubicTo(21.49, 10, 21.65, 11.63, 21.64, 13.25)
      ..cubicTo(21.64, 13.81, 21.63, 14.23, 21.61, 14.62)
      ..cubicTo(21.59, 14.87, 21.38, 15.07, 21.13, 15.04)
      ..cubicTo(20.88, 15.03, 20.69, 14.82, 20.71, 14.57)
      ..cubicTo(20.73, 14.2, 20.74, 13.79, 20.74, 13.24)
      ..cubicTo(20.75, 11.68, 20.6, 10.1, 20.3, 8.56)
      ..cubicTo(20.19, 8.01, 20.08, 7.53, 19.95, 7.09)
      ..cubicTo(19.16, 4.33, 17.87, 2.6, 16.58, 2.55)
      ..lineTo(16.47, 2.55)
      ..cubicTo(15.18, 2.6, 13.89, 4.33, 13.1, 7.09)
      ..cubicTo(12.97, 7.53, 12.86, 8.01, 12.74, 8.57)
      ..cubicTo(12.45, 10.11, 12.3, 11.68, 12.31, 13.24)
      ..cubicTo(12.3, 14.81, 12.45, 16.38, 12.74, 17.92)
      ..cubicTo(12.82, 18.26, 12.89, 18.61, 12.99, 18.97)
      ..cubicTo(13.05, 19.21, 12.9, 19.46, 12.66, 19.52)
      ..cubicTo(12.61, 19.53, 12.57, 19.54, 12.54, 19.54)
      ..close(),
    Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(16.52, 15.33)
      ..cubicTo(16.27, 15.33, 16.07, 15.12, 16.07, 14.88)
      ..lineTo(16.07, 2.11)
      ..cubicTo(16.07, 1.86, 16.27, 1.66, 16.52, 1.66)
      ..cubicTo(16.77, 1.66, 16.97, 1.86, 16.97, 2.11)
      ..lineTo(16.97, 14.88)
      ..cubicTo(16.97, 15.12, 16.77, 15.33, 16.52, 15.33)
      ..close(),
    Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(27.67, 13.7)
      ..lineTo(5.37, 13.7)
      ..cubicTo(5.12, 13.7, 4.92, 13.5, 4.92, 13.25)
      ..cubicTo(4.92, 13.01, 5.12, 12.8, 5.37, 12.8)
      ..lineTo(27.67, 12.8)
      ..cubicTo(27.92, 12.8, 28.12, 13.01, 28.12, 13.25)
      ..cubicTo(28.12, 13.5, 27.92, 13.7, 27.67, 13.7)
      ..close(),
    Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(25.73, 7.42)
      ..lineTo(7.3, 7.42)
      ..cubicTo(7.06, 7.42, 6.86, 7.22, 6.86, 6.98)
      ..cubicTo(6.86, 6.73, 7.06, 6.53, 7.3, 6.53)
      ..lineTo(25.74, 6.53)
      ..cubicTo(25.98, 6.53, 26.19, 6.73, 26.19, 6.98)
      ..cubicTo(26.19, 7.22, 25.98, 7.42, 25.73, 7.42)
      ..close(),
    Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(25.33, 26.96)
      ..cubicTo(25.23, 26.96, 25.13, 26.92, 25.05, 26.86)
      ..lineTo(21.06, 23.7)
      ..lineTo(17.75, 23.7)
      ..cubicTo(17.5, 23.7, 17.3, 23.5, 17.3, 23.25)
      ..cubicTo(17.3, 23, 17.5, 22.8, 17.75, 22.8)
      ..lineTo(21.22, 22.8)
      ..cubicTo(21.32, 22.8, 21.42, 22.83, 21.5, 22.89)
      ..lineTo(24.88, 25.57)
      ..lineTo(24.88, 23.25)
      ..cubicTo(24.88, 23, 25.08, 22.8, 25.33, 22.8)
      ..cubicTo(26.37, 22.8, 27.2, 21.96, 27.2, 20.93)
      ..lineTo(27.2, 16.92)
      ..cubicTo(27.2, 15.89, 26.37, 15.05, 25.33, 15.05)
      ..lineTo(17.61, 15.05)
      ..cubicTo(16.58, 15.05, 15.74, 15.89, 15.74, 16.92)
      ..lineTo(15.74, 19.09)
      ..cubicTo(15.74, 19.34, 15.54, 19.54, 15.29, 19.54)
      ..cubicTo(15.04, 19.54, 14.84, 19.34, 14.84, 19.09)
      ..lineTo(14.84, 16.92)
      ..cubicTo(14.84, 15.39, 16.09, 14.15, 17.62, 14.15)
      ..lineTo(25.35, 14.15)
      ..cubicTo(26.88, 14.15, 28.12, 15.39, 28.12, 16.92)
      ..lineTo(28.12, 20.93)
      ..cubicTo(28.12, 22.3, 27.12, 23.45, 25.8, 23.66)
      ..lineTo(25.8, 26.5)
      ..cubicTo(25.8, 26.68, 25.69, 26.83, 25.54, 26.91)
      ..cubicTo(25.47, 26.94, 25.4, 26.96, 25.33, 26.96)
      ..close(),
    Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(19.22, 21.88)
      ..cubicTo(19.16, 21.88, 19.1, 21.87, 19.04, 21.85)
      ..cubicTo(18.81, 21.75, 18.71, 21.48, 18.81, 21.26)
      ..lineTo(21.05, 15.98)
      ..cubicTo(21.13, 15.81, 21.29, 15.7, 21.47, 15.7)
      ..cubicTo(21.65, 15.7, 21.81, 15.81, 21.88, 15.98)
      ..lineTo(24.15, 21.26)
      ..cubicTo(24.25, 21.48, 24.14, 21.75, 23.91, 21.85)
      ..cubicTo(23.68, 21.95, 23.41, 21.84, 23.32, 21.61)
      ..lineTo(21.47, 17.31)
      ..lineTo(19.63, 21.61)
      ..cubicTo(19.56, 21.78, 19.39, 21.88, 19.22, 21.88)
      ..close(),
    Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(23.03, 20.25)
      ..lineTo(19.92, 20.25)
      ..cubicTo(19.67, 20.25, 19.47, 20.05, 19.47, 19.8)
      ..cubicTo(19.47, 19.55, 19.67, 19.35, 19.92, 19.35)
      ..lineTo(23.03, 19.35)
      ..cubicTo(23.28, 19.35, 23.48, 19.55, 23.48, 19.8)
      ..cubicTo(23.48, 20.05, 23.28, 20.25, 23.03, 20.25)
      ..close(),
    Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(15.43, 19.55)
      ..lineTo(7.7, 19.55)
      ..cubicTo(6.67, 19.55, 5.83, 20.38, 5.83, 21.42)
      ..lineTo(5.83, 25.42)
      ..cubicTo(5.83, 26.45, 6.67, 27.29, 7.7, 27.29)
      ..cubicTo(7.95, 27.29, 8.15, 27.49, 8.15, 27.74)
      ..lineTo(8.15, 30.06)
      ..lineTo(11.53, 27.39)
      ..cubicTo(11.61, 27.33, 11.71, 27.29, 11.81, 27.29)
      ..lineTo(15.42, 27.29)
      ..cubicTo(16.45, 27.29, 17.29, 26.45, 17.29, 25.41)
      ..lineTo(17.29, 21.41)
      ..cubicTo(17.3, 20.38, 16.46, 19.55, 15.43, 19.55)
      ..close()
      ..moveTo(7.7, 31.45)
      ..cubicTo(7.63, 31.45, 7.57, 31.44, 7.51, 31.4)
      ..cubicTo(7.35, 31.33, 7.25, 31.17, 7.25, 30.99)
      ..lineTo(7.25, 28.16)
      ..cubicTo(5.94, 27.94, 4.92, 26.8, 4.92, 25.42)
      ..lineTo(4.92, 21.42)
      ..cubicTo(4.92, 19.89, 6.17, 18.64, 7.7, 18.64)
      ..lineTo(15.43, 18.64)
      ..cubicTo(16.96, 18.64, 18.2, 19.89, 18.2, 21.42)
      ..lineTo(18.2, 25.42)
      ..cubicTo(18.2, 26.95, 16.96, 28.2, 15.43, 28.2)
      ..lineTo(11.97, 28.2)
      ..lineTo(7.98, 31.36)
      ..cubicTo(7.89, 31.42, 7.8, 31.45, 7.7, 31.45)
      ..close(),
    Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(14.2, 22.37)
      ..lineTo(8.77, 22.37)
      ..cubicTo(8.53, 22.37, 8.32, 22.17, 8.32, 21.92)
      ..cubicTo(8.32, 21.67, 8.53, 21.47, 8.77, 21.47)
      ..lineTo(14.2, 21.47)
      ..cubicTo(14.45, 21.47, 14.65, 21.67, 14.65, 21.92)
      ..cubicTo(14.65, 22.17, 14.45, 22.37, 14.2, 22.37)
      ..close(),
    Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(9.22, 27.31)
      ..cubicTo(9.06, 27.31, 8.91, 27.23, 8.83, 27.09)
      ..cubicTo(8.7, 26.88, 8.77, 26.6, 8.98, 26.47)
      ..cubicTo(11.9, 24.74, 13.19, 21.86, 13.21, 21.83)
      ..cubicTo(13.31, 21.6, 13.57, 21.5, 13.8, 21.6)
      ..cubicTo(14.03, 21.7, 14.14, 21.97, 14.04, 22.19)
      ..cubicTo(13.98, 22.32, 12.63, 25.36, 9.44, 27.25)
      ..cubicTo(9.37, 27.29, 9.29, 27.31, 9.22, 27.31)
      ..close(),
    Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(14.35, 26.88)
      ..cubicTo(14.33, 26.88, 14.3, 26.88, 14.27, 26.87)
      ..cubicTo(11.02, 26.3, 9.54, 23.01, 9.48, 22.87)
      ..cubicTo(9.38, 22.64, 9.49, 22.38, 9.71, 22.27)
      ..cubicTo(9.94, 22.17, 10.21, 22.27, 10.31, 22.5)
      ..cubicTo(10.32, 22.54, 11.67, 25.49, 14.44, 25.97)
      ..cubicTo(14.68, 26.01, 14.84, 26.25, 14.8, 26.49)
      ..cubicTo(14.76, 26.72, 14.57, 26.88, 14.35, 26.88)
      ..close(),
    Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(11.48, 22.37)
      ..cubicTo(11.24, 22.37, 11.03, 22.17, 11.03, 21.92)
      ..lineTo(11.03, 20.32)
      ..cubicTo(11.03, 20.07, 11.24, 19.87, 11.48, 19.87)
      ..cubicTo(11.73, 19.87, 11.93, 20.07, 11.93, 20.32)
      ..lineTo(11.93, 21.92)
      ..cubicTo(11.94, 22.17, 11.74, 22.37, 11.48, 22.37)
      ..close(),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _box, size.height / _box);
    final Paint paint = Paint()..color = color;
    for (final Path p in _paths) {
      canvas.drawPath(p, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LanguageGlyphPainter old) => old.color != color;
}
