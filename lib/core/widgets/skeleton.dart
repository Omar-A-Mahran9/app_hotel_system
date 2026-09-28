import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';

/// Reusable skeleton (shimmer) building blocks for loading states.
///
/// The Figma shows skeleton placeholders — not centred spinners — while lists
/// and image-heavy screens load (`الغرف المتاحة`). Wrap a tree of [SkeletonBox]
/// / [SkeletonText] / [SkeletonImage] in a single [Skeleton] so they share one
/// animation controller. Presets ([SkeletonRoomList], [SkeletonListCards]) are
/// ready to drop into `UiStateView.skeleton`.
///
/// No third-party dependency — one [AnimationController] per [Skeleton] scope.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.child});

  final Widget child;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerScope(animation: _controller, child: widget.child);
  }
}

class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required this.animation, required super.child});

  final Animation<double> animation;

  static _ShimmerScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>();

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) =>
      oldWidget.animation != animation;
}

/// A single shimmering placeholder rectangle.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 15,
    this.borderRadius = AppRadius.allSm,
  });

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color base = theme.colorScheme.surfaceContainerHighest;
    final Color highlight = Color.alphaBlend(
      theme.colorScheme.surface.withValues(alpha: 0.6),
      base,
    );

    final _ShimmerScope? scope = _ShimmerScope.maybeOf(context);
    final Widget box = SizedBox(width: width, height: height);

    if (scope == null) {
      return DecoratedBox(
        decoration: BoxDecoration(color: base, borderRadius: borderRadius),
        child: box,
      );
    }

    return AnimatedBuilder(
      animation: scope.animation,
      builder: (BuildContext context, _) {
        final double t = scope.animation.value;
        return ClipRRect(
          borderRadius: borderRadius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1 - 2 * (1 - t), 0),
                end: Alignment(1 - 2 * (1 - t), 0),
                colors: <Color>[base, highlight, base],
                stops: const <double>[0.35, 0.5, 0.65],
              ),
            ),
            child: box,
          ),
        );
      },
    );
  }
}

/// Several stacked text-line skeletons; the last line is shortened.
class SkeletonText extends StatelessWidget {
  const SkeletonText({
    super.key,
    this.lines = 3,
    this.lineHeight = 13,
    this.spacing = AppSpacing.xs,
    this.lastLineFraction = 0.55,
  });

  final int lines;
  final double lineHeight;
  final double spacing;
  final double lastLineFraction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < lines; i++) ...<Widget>[
          if (i > 0) SizedBox(height: spacing),
          FractionallySizedBox(
            widthFactor: i == lines - 1 ? lastLineFraction : 1,
            child: SkeletonBox(height: lineHeight),
          ),
        ],
      ],
    );
  }
}

/// An image-shaped skeleton block.
class SkeletonImage extends StatelessWidget {
  const SkeletonImage({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppRadius.allMd,
  });

  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height ?? 96,
      borderRadius: borderRadius,
    );
  }
}

/// A card-shaped skeleton: thumbnail + title + two lines + a footer row.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.thumb = true});

  final bool thumb;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const <Widget>[
                    SkeletonBox(width: 140, height: 17),
                    SizedBox(height: AppSpacing.xs),
                    SkeletonText(lines: 2, lineHeight: 13),
                  ],
                ),
              ),
              if (thumb) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                const SkeletonImage(width: 84, height: 84),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: const <Widget>[
              SkeletonBox(
                width: 80,
                height: 20,
                borderRadius: AppRadius.allPill,
              ),
              Spacer(),
              SkeletonBox(width: 56, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}

/// A vertical list of [SkeletonCard]s inside a [Skeleton] scope.
class SkeletonListCards extends StatelessWidget {
  const SkeletonListCards({
    super.key,
    this.itemCount = 4,
    this.padding = const EdgeInsets.all(AppSpacing.pageGutter),
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, _) => const SkeletonCard(),
      ),
    );
  }
}

/// The `الغرف المتاحة` loading state: a stay-summary bar skeleton then room
/// cards.
class SkeletonRoomList extends StatelessWidget {
  const SkeletonRoomList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageGutter),
        physics: const NeverScrollableScrollPhysics(),
        children: <Widget>[
          const SkeletonBox(height: 88, borderRadius: AppRadius.allCard),
          const SizedBox(height: AppSpacing.md),
          for (int i = 0; i < itemCount; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            const SkeletonCard(),
          ],
        ],
      ),
    );
  }
}
