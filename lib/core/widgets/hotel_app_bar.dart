import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_icons.dart';

/// Standard app bar for the Guest App.
///
/// Figma app bars are flat, background-aware (no Material surface tint or
/// scroll elevation), with a **centred title** and a plain directional back
/// affordance — `←` in LTR, `→` in RTL (matching the Figma Arabic frames).
/// The visual defaults live in [ThemeData.appBarTheme]; this widget pins the
/// back glyph and keeps a single import for screens.
class HotelAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HotelAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.fallbackLocation,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool automaticallyImplyLeading;

  /// Where the back button goes when there is nothing to pop — e.g. the
  /// screen was reached with `context.go` or opened directly by URL. When
  /// null, such a screen simply shows no back button.
  final String? fallbackLocation;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    final bool canPop = route?.canPop ?? false;
    final Widget? resolvedLeading =
        leading ??
        (automaticallyImplyLeading && (canPop || fallbackLocation != null)
            ? _DirectionalBackButton(
                fallbackLocation: canPop ? null : fallbackLocation,
              )
            : null);

    return AppBar(
      title: Text(title, overflow: TextOverflow.ellipsis),
      centerTitle: centerTitle,
      actions: actions,
      leading: resolvedLeading,
      automaticallyImplyLeading: false,
    );
  }
}

/// Back button whose glyph follows the reading direction: `arrow_back` in LTR,
/// `arrow_forward` in RTL — so the Arabic layout shows the Figma's `→`.
class _DirectionalBackButton extends StatelessWidget {
  const _DirectionalBackButton({this.fallbackLocation});

  final String? fallbackLocation;

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return IconButton(
      icon: Icon(AppIcons.backFor(rtl ? TextDirection.rtl : TextDirection.ltr)),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        final String? fallback = fallbackLocation;
        if (fallback != null) {
          context.go(fallback);
        } else {
          Navigator.maybePop(context);
        }
      },
    );
  }
}
