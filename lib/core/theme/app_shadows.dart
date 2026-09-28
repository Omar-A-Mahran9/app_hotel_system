import 'package:flutter/material.dart';

/// Elevation tokens — the Figma `elevation/1‑4` styles
/// (`design-system-tokens.md` §7).
///
/// The design language is minimal: *"Near-black at 4-12% opacity, never a grey
/// blur. In a minimal UI a 1px border does most of the separating — elevation is
/// reserved for things that genuinely float."* Shadow colour is a single
/// near-black `#101517` (from the `ink` ramp); opacity is carried in the alpha
/// byte. `elevation4` casts **upward** — the one inverted shadow.
abstract final class AppShadows {
  // #101517 at 4% / 5% / 6% / 12%.
  static const Color _s04 = Color(0x0A101517);
  static const Color _s05 = Color(0x0D101517);
  static const Color _s06 = Color(0x0F101517);
  static const Color _s12 = Color(0x1F101517);

  /// Resting card / list container / search field. Pair with a 1px border.
  static const List<BoxShadow> elevation1 = <BoxShadow>[
    BoxShadow(color: _s04, offset: Offset(0, 1), blurRadius: 2),
  ];

  /// Tab bar, sticky header — sticky surfaces.
  static const List<BoxShadow> elevation2 = <BoxShadow>[
    BoxShadow(color: _s04, offset: Offset(0, 2), blurRadius: 4),
  ];

  /// FAB, popover, digital-key hero.
  static const List<BoxShadow> elevation3 = <BoxShadow>[
    BoxShadow(color: _s05, offset: Offset(0, 4), blurRadius: 8, spreadRadius: -2),
  ];

  /// Bottom sheet / sticky bottom action bar — casts **upward** so content
  /// reads as sliding under it.
  static const List<BoxShadow> elevation4 = <BoxShadow>[
    BoxShadow(
      color: _s12,
      offset: Offset(0, -4),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  /// Soft all-round lift for a white tile on a white canvas (v2 `Empty State`
  /// icon tile): two centred blurs, 2px @ 4% + 3px @ 6%.
  static const List<BoxShadow> tile = <BoxShadow>[
    BoxShadow(color: _s04, blurRadius: 2),
    BoxShadow(color: _s06, blurRadius: 3),
  ];

  /// No shadow — dark theme, where surfaces separate by colour.
  static const List<BoxShadow> none = <BoxShadow>[];

  // ── Semantic aliases ────────────────────────────────────────────────────
  /// Resting surface (cards, list containers). → [elevation1].
  static const List<BoxShadow> card = elevation1;

  /// Raised surface (sticky bottom bar, bottom sheet). → [elevation4].
  static const List<BoxShadow> raised = elevation4;
}
