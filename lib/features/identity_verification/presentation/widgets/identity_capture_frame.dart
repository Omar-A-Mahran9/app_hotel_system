import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/bottom_action_bar.dart';
import '../../domain/entities/identity_document.dart';

/// The full-bleed dark camera screens of `10 · Identity verification`
/// (`IDENTITY_CaptureID`, `IDENTITY_ReviewID`, `IDENTITY_Selfie`), laid out
/// to the 393-wide Figma frames:
///
/// * `#171412` canvas, light status bar, 44px circular back button;
/// * title (24 bold) + sub-line (15, 72% white) centred under the status bar;
/// * the 280×360 capture frame — 2px white dashes `[16, 12]`, radius 32 —
///   with a 180×220 face-guide oval at 35% white;
/// * a hint pill (12, white) and either the 76px white shutter (capture) or
///   the confirm / retake footer (review, [footer]);
/// * the "stored securely" footnote (12, 60% white).
///
/// On the review screen the real captured photo ([preview]) fills the frame.
///
/// ID capture uses a landscape frame in the ID-1 card ratio (85.6 × 54 mm)
/// with corner guides ([IdentityFrameShape.card]); the selfie keeps the
/// portrait frame with the face oval. When [live] is given (iOS/Android), the
/// camera feed is shown inside the frame so the card can be lined up before
/// the shot, and [tips] list what makes a readable photo.
class IdentityCaptureScreen extends StatelessWidget {
  const IdentityCaptureScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.footnote,
    required this.backTooltip,
    required this.onBack,
    this.onShutter,
    this.shutterLabel,
    this.preview,
    this.footer,
    this.shape = IdentityFrameShape.face,
    this.live,
    this.tips = const <String>[],
  });

  final String title;
  final String subtitle;
  final String hint;
  final String footnote;
  final String backTooltip;
  final VoidCallback onBack;

  /// Shows the shutter when non-null (capture screens).
  final VoidCallback? onShutter;
  final String? shutterLabel;

  /// The captured photo to show inside the frame (review screen).
  final CapturedImage? preview;

  /// Replaces the shutter with an action footer (review screen).
  final Widget? footer;

  final IdentityFrameShape shape;

  /// The live camera feed, laid out inside the frame (capture screens).
  final Widget? live;

  /// Short capture instructions shown under the frame.
  final List<String> tips;

  static const Color _canvas = AppPrimitives.ink900;
  static const double _frameWidth = 280;
  static const double _frameHeight = 360;

  /// ID-1 card (85.6 × 53.98 mm).
  static const double _cardRatio = 85.6 / 53.98;
  static const double _cardMaxWidth = 345;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color white = AppPrimitives.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _canvas,
        body: SafeArea(
          bottom: footer == null,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // The frame shrinks on short screens so the shutter + footnote
              // always stay visible.
              final double frameScale =
                  ((constraints.maxHeight - 420 - tips.length * 24) / _frameHeight).clamp(0.6, 1.0);
              final double cardWidth =
                  (constraints.maxWidth - 48).clamp(200.0, _cardMaxWidth);
              final Size frame = shape == IdentityFrameShape.card
                  ? Size(cardWidth, cardWidth / _cardRatio)
                  : Size(_frameWidth * frameScale, _frameHeight * frameScale);
              return Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 2, 16, 0),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _BackButton(tooltip: backTooltip, onPressed: onBack),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: <Widget>[
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: text.headlineSmall?.copyWith(
                            color: white,
                            fontSize: 24,
                            height: 36 / 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: text.bodyLarge?.copyWith(
                            color: white.withValues(alpha: 0.72),
                            fontSize: 15,
                            height: 26 / 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: shape == IdentityFrameShape.card ? 32 : 20),
                  SizedBox(
                    width: frame.width,
                    height: frame.height,
                    child: _CaptureFrame(preview: preview, shape: shape, live: live),
                  ),
                  const SizedBox(height: 24),
                  if (tips.isNotEmpty) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: _Tips(tips: tips),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _HintPill(text: hint),
                  const Spacer(),
                  if (onShutter != null) ...<Widget>[
                    _ShutterButton(onPressed: onShutter!, label: shutterLabel),
                    const SizedBox(height: 24),
                  ],
                  if (footer == null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(46, 0, 46, AppSpacing.lg),
                      child: _Footnote(text: footnote),
                    ),
                  if (footer != null) ...<Widget>[
                    footer!,
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        41,
                        0,
                        41,
                        MediaQuery.paddingOf(context).bottom + AppSpacing.xs,
                      ),
                      child: _Footnote(text: footnote),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The review screen's confirm / retake actions on the dark canvas.
class IdentityCaptureFooter extends StatelessWidget {
  const IdentityCaptureFooter({super.key, required this.primary, required this.secondary});

  final Widget primary;
  final Widget secondary;

  @override
  Widget build(BuildContext context) {
    return BottomActionBar.actions(
      primary: primary,
      secondary: secondary,
      // Transparent over the dark canvas — no raised surface or shadow.
      floating: false,
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppPrimitives.white,
        shape: const CircleBorder(
          side: BorderSide(color: AppPrimitives.stone200, width: 0.5),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(
              AppIcons.heroBackFor(Directionality.of(context)),
              size: 20,
              color: context.colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// The capture frame's shape: the ID card (landscape, corner guides) or the
/// selfie (portrait, face oval).
enum IdentityFrameShape { card, face }

class _CaptureFrame extends StatelessWidget {
  const _CaptureFrame({required this.preview, required this.shape, this.live});

  final CapturedImage? preview;
  final IdentityFrameShape shape;
  final Widget? live;

  @override
  Widget build(BuildContext context) {
    final bool card = shape == IdentityFrameShape.card;
    final BorderRadius radius = BorderRadius.circular(card ? 16 : 32);
    final Uint8List? bytes = preview?.bytes;
    final String? path = preview?.filePath;
    final Widget? content = bytes != null
        ? Image.memory(bytes, fit: BoxFit.cover)
        : (path != null && !kIsWeb)
            ? Image.file(File(path), fit: BoxFit.cover)
            : live;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (content != null)
          ClipRRect(borderRadius: radius, child: content)
        else if (card)
          // Placeholder card silhouette.
          const Center(
            child: Icon(AppIcons.identity, size: 64, color: Color(0x59FFFFFF)),
          ),
        if (!card && (content == null || live != null))
          // 180×220 of the 280×360 frame, centred — over the live feed too.
          const FractionallySizedBox(
            widthFactor: 180 / 280,
            heightFactor: 220 / 360,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                shape: StadiumBorder(
                  side: BorderSide(color: Color(0x59FFFFFF)),
                ),
              ),
            ),
          ),
        CustomPaint(painter: card ? const _CornerGuidesPainter() : const _DashedFramePainter()),
      ],
    );
  }
}

class _Tips extends StatelessWidget {
  const _Tips({required this.tips});

  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppPrimitives.white.withValues(alpha: 0.85),
          fontSize: 13,
          height: 20 / 13,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final String tip in tips)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(AppIcons.successOutline, size: 16, color: AppPrimitives.white),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(tip, style: style)),
              ],
            ),
          ),
      ],
    );
  }
}

class _HintPill extends StatelessWidget {
  const _HintPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: IdentityCaptureScreen._canvas,
        shape: StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppPrimitives.white,
                fontSize: 12,
                height: 18 / 12,
                fontWeight: FontWeight.w400,
              ),
        ),
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppPrimitives.white.withValues(alpha: 0.6),
            fontSize: 12,
            height: 18 / 12,
            fontWeight: FontWeight.w400,
          ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.onPressed, this.label});

  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    // 76px white disc with a 4px white ring drawn outside it (Figma
    // `stroke=#ffffff/4/OUTSIDE`), separated by the dark canvas.
    return Semantics(
      button: true,
      label: label,
      child: Container(
        width: 76 + 8,
        height: 76 + 8,
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppPrimitives.white,
        ),
        child: Material(
          key: const ValueKey('identityShutterButton'),
          color: AppPrimitives.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Icon(AppIcons.cameraLinear, size: 28, color: context.colors.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _DashedFramePainter extends CustomPainter {
  const _DashedFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppPrimitives.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Stroke drawn inside the frame bounds (Figma `strokeAlign: INSIDE`).
    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          const Radius.circular(31),
        ),
      );

    const double dashWidth = 16;
    const double dashSpace = 12;
    for (final ui.PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedFramePainter oldDelegate) => false;
}

/// A thin outline of the card plus thick white corner brackets — "put the
/// card's four corners here".
class _CornerGuidesPainter extends CustomPainter {
  const _CornerGuidesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double r = 16;
    final RRect outline = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(r - 1),
    );
    canvas.drawRRect(
      outline,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    final Paint corner = Paint()
      ..color = AppPrimitives.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const double arm = 28;
    final double w = size.width - 2;
    final double h = size.height - 2;
    for (final (double x, double y, double dx, double dy) in <(double, double, double, double)>[
      (2, 2, 1, 1),
      (w, 2, -1, 1),
      (2, h, 1, -1),
      (w, h, -1, -1),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y + dy * arm)
          ..lineTo(x, y + dy * r)
          ..arcToPoint(Offset(x + dx * r, y), radius: const Radius.circular(r), clockwise: dx * dy > 0)
          ..lineTo(x + dx * arm, y),
        corner,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CornerGuidesPainter oldDelegate) => false;
}
