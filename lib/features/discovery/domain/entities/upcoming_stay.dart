import 'package:flutter/foundation.dart';

import 'localized_text.dart';
import 'money.dart';

/// The guest's next confirmed stay, shown as the `إقامتك القادمة` card at the top
/// of the Home screen (`HOME_Default` mockup).
///
/// This is a display snapshot only. The authoritative reservation lives in the
/// reservations feature / Laravel; the discovery dummy layer supplies one so the
/// Home card can be built. `reservationId` links the card to its reservation
/// screen.
@immutable
class UpcomingStay {
  const UpcomingStay({
    required this.reservationId,
    required this.roomName,
    required this.hotelName,
    required this.cityName,
    required this.nightlyRate,
    required this.isAvailable,
    this.imageUrl,
    this.imageSeed,
  });

  final String reservationId;
  final LocalizedText roomName;
  final LocalizedText hotelName;
  final LocalizedText cityName;
  final Money nightlyRate;

  /// Whether the stay is still active/holdable — drives the `متاحة` pill.
  final bool isAvailable;

  /// Real reservation/hotel imagery, when the API supplies it.
  final String? imageUrl;

  /// Stable Figma photo key used only by the dummy-data fixture.
  final String? imageSeed;

  @override
  bool operator ==(Object other) =>
      other is UpcomingStay &&
      other.reservationId == reservationId &&
      other.roomName == roomName &&
      other.hotelName == hotelName &&
      other.cityName == cityName &&
      other.nightlyRate == nightlyRate &&
      other.isAvailable == isAvailable &&
      other.imageUrl == imageUrl &&
      other.imageSeed == imageSeed;

  @override
  int get hashCode => Object.hash(
        reservationId,
        roomName,
        hotelName,
        cityName,
        nightlyRate,
        isAvailable,
        imageUrl,
        imageSeed,
      );
}
