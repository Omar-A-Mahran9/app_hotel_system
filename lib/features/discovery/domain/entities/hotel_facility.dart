import 'package:flutter/foundation.dart';

import 'localized_text.dart';

/// One entry in a specific hotel's real facility catalog membership
/// (`amenities` on the backend hotel resource — each `{key, label, icon}`).
///
/// The backend's facility catalog is open and admin-managed (a real
/// database table staff can add to), not a fixed enum — unlike
/// [HotelAmenity] (used only by the search *filter*, a separate, smaller,
/// currently-fixed vocabulary). A widget must render whatever [label] the
/// backend returns; it must never look [key] up in a hardcoded key->label
/// map, which would silently drop a newly-added facility.
@immutable
class HotelFacility {
  const HotelFacility({
    required this.key,
    required this.label,
    this.description,
    this.icon,
  });

  final String key;
  final LocalizedText label;

  /// Optional operator-written description; `null` when none is on file.
  final LocalizedText? description;

  /// The facility's own icon key (e.g. `"wifi"`), or `null`. Mapped to a
  /// glyph in the UI layer (`AppIcons.forFacility`); an unrecognized/absent
  /// key falls back to a neutral marker, never a guessed one.
  final String? icon;

  @override
  bool operator ==(Object other) =>
      other is HotelFacility &&
      other.key == key &&
      other.label == label &&
      other.description == description &&
      other.icon == icon;

  @override
  int get hashCode => Object.hash(key, label, description, icon);
}
