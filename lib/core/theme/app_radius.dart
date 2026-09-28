import 'package:flutter/widgets.dart';

/// Corner-radius scale — the Figma `Radius` collection (`design-system-tokens.md`
/// §5): `xs 4 · sm 8 · md 14 · lg 20 · xl 24 · xxl 32 · full 999`.
///
/// `input` (= `md`, 14) and `card` (= `lg`, 20) are semantic aliases kept for
/// readability at call sites. `pill`/`full` (999) is the button + chip + avatar
/// radius. `sheet` (= `xxl`, 32) is the bottom-sheet / raised-panel radius.
abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double full = 999;

  // ── Semantic aliases ────────────────────────────────────────────────────
  static const double input = md; // 14
  static const double card = lg; // 20
  static const double sheet = xxl; // 32
  static const double pill = full; // 999

  static const BorderRadius allXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius all2xl = BorderRadius.all(Radius.circular(xxl));

  static const BorderRadius allInput = allMd;
  static const BorderRadius allCard = allLg;
  static const BorderRadius allPill = BorderRadius.all(Radius.circular(pill));

  /// Top-only rounding for bottom sheets / raised panels (`sheet` = 32).
  static const BorderRadius topSheet = BorderRadius.vertical(
    top: Radius.circular(sheet),
  );
}
