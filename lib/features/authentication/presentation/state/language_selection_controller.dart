import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the guest has confirmed an app language on the first-run
/// `01 · Entry` language screen.
///
/// `false` on a cold start routes the guest to `AppRoutes.language` before the
/// entry screen; [markSelected] flips it once they tap "متابعة" so the screen is
/// not shown again for the rest of the session.
///
/// Phase 0 keeps this in memory only — like the locale and theme-mode
/// controllers, persistence is deferred with the rest of the storage layer
/// (`core/storage/`). Until then the screen reappears on every cold start,
/// which is acceptable pre-release.
class LanguageSelectionController extends Notifier<bool> {
  @override
  bool build() => false;

  void markSelected() => state = true;
}

final languageSelectedProvider =
    NotifierProvider<LanguageSelectionController, bool>(
      LanguageSelectionController.new,
    );
