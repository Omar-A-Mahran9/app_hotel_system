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

  static const Color _canvas = AppPrimitives.ink900;
  static const double _frameWidth = 280;
  static const double _frameHeight = 360;

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
                  ((constraints.maxHeight - 420) / _frameHeight).clamp(0.6, 1.0);
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: _frameWidth * frameScale,
                    height: _frameHeight * frameScale,
                    child: _CaptureFrame(preview: preview),
                  ),
                  const SizedBox(height: 24),
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

class _CaptureFrame extends StatelessWidget {
  const _CaptureFrame({required this.preview});

  final CapturedImage? preview;

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = preview?.bytes;
    final String? path = preview?.filePath;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (bytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Image.memory(bytes, fit: BoxFit.cover),
          )
        else if (path != null && !kIsWeb)
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Image.file(File(path), fit: BoxFit.cover),
          )
        else
          // 180×220 of the 280×360 frame, centred.
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
        const CustomPaint(painter: _DashedFramePainter()),
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
