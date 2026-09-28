import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the user's [ThemeMode] selection.
///
/// Phase 0 keeps the choice in memory only. Persistence (secure/shared storage)
/// is deferred to a later phase together with the storage abstraction in
/// `core/storage/` — see [StateNotifier] wiring in `app/app.dart`.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void set(ThemeMode mode) => state = mode;
}

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
