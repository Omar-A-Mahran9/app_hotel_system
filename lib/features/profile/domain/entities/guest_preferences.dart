import 'package:flutter/foundation.dart';

/// `PROFILE_Preferences` — what every hotel of the group reads to prepare
/// the guest's room, plus their email/SMS opt-out. Mirrors
/// `Guest::PREFERENCE_DEFAULTS` / `resolvedPreferences()` on the backend.
@immutable
class GuestPreferences {
  const GuestPreferences({
    required this.highFloor,
    required this.extraPillows,
    required this.notificationsEnabled,
  });

  /// The backend defaults for a guest who hasn't chosen yet.
  static const GuestPreferences defaults = GuestPreferences(
    highFloor: false,
    extraPillows: false,
    notificationsEnabled: true,
  );

  final bool highFloor;
  final bool extraPillows;

  /// `false` = no email/SMS lifecycle messages (the in-app feed stays).
  final bool notificationsEnabled;

  GuestPreferences copyWith({bool? highFloor, bool? extraPillows, bool? notificationsEnabled}) =>
      GuestPreferences(
        highFloor: highFloor ?? this.highFloor,
        extraPillows: extraPillows ?? this.extraPillows,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );

  @override
  bool operator ==(Object other) =>
      other is GuestPreferences &&
      other.highFloor == highFloor &&
      other.extraPillows == extraPillows &&
      other.notificationsEnabled == notificationsEnabled;

  @override
  int get hashCode => Object.hash(highFloor, extraPillows, notificationsEnabled);
}

/// The server-side account extras shown on the profile screens.
@immutable
class GuestAccountSettings {
  const GuestAccountSettings({
    required this.preferences,
    required this.dataDeletionRequestedAt,
    this.keepIdentityForFuture = false,
  });

  final GuestPreferences preferences;

  /// When the guest asked for their data to be deleted (`PROFILE_Privacy`).
  final DateTime? dataDeletionRequestedAt;

  /// `PROFILE_Privacy` identity choice: false = delete the images after
  /// checkout (default); true = keep them for future bookings.
  final bool keepIdentityForFuture;

  @override
  bool operator ==(Object other) =>
      other is GuestAccountSettings &&
      other.preferences == preferences &&
      other.dataDeletionRequestedAt == dataDeletionRequestedAt &&
      other.keepIdentityForFuture == keepIdentityForFuture;

  @override
  int get hashCode => Object.hash(preferences, dataDeletionRequestedAt, keepIdentityForFuture);
}
