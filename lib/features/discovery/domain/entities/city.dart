import 'package:flutter/foundation.dart';

import 'localized_text.dart';

/// A destination the group operates in. Used by the city filter and the search
/// suggestions in `15 · Search, filters & sort`.
@immutable
class City {
  const City({
    required this.id,
    required this.name,
    required this.hotelCount,
  });

  final String id;
  final LocalizedText name;

  /// How many group hotels are in this city — shown next to the name in the
  /// picker (`الرياض · ٤ فنادق`).
  final int hotelCount;

  @override
  bool operator ==(Object other) =>
      other is City &&
      other.id == id &&
      other.name == name &&
      other.hotelCount == hotelCount;

  @override
  int get hashCode => Object.hash(id, name, hotelCount);
}
