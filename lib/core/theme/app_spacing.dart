/// Spacing scale — the Figma `Spacing` collection (`design-system-tokens.md` §4).
///
/// Base unit 8. `space1` (4) is the only half-step and exists **only** for
/// icon-to-label gaps and dense chips — nothing else sits off the grid.
///
/// `spaceN` are the canonical names; the older `xxs…xxxl` names are kept as
/// aliases (identical values) so existing call sites don't churn.
abstract final class AppSpacing {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space7 = 32;
  static const double space8 = 40;
  static const double space9 = 48;
  static const double space10 = 64;

  // ── Legacy aliases (values unchanged) ────────────────────────────────────
  static const double xxs = space1;
  static const double xs = space2;
  static const double sm = space3;
  static const double md = space4;
  static const double lg = space5;
  static const double xl = space6;
  static const double xxl = space7;
  static const double xxxl = space9;

  /// Default horizontal page padding for phone layouts (`space6`) — every
  /// v2 frame lays its 345px content 24px in from a 393px screen.
  static const double pageGutter = space6;

  /// Default inner padding for [AppCard] / surface containers (`space4`).
  static const double cardPadding = space4;

  /// Vertical gap between stacked sections on a screen (`space6`).
  static const double section = space6;

  /// Space above a sticky bottom action bar's content and below its buttons
  /// (added on top of the safe-area inset). See `BottomActionBar`.
  static const double bottomBarTop = space3;
  static const double bottomBarBottom = space4;
}
