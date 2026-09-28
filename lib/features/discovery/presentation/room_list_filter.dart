import '../domain/entities/available_room.dart';
import '../domain/entities/room_type_summary.dart';

class RoomListFilter {
  const RoomListFilter({
    this.freeCancellationOnly = false,
    this.breakfastOnly = false,
    this.wifiOnly = false,
  });

  final bool freeCancellationOnly;
  final bool breakfastOnly;
  final bool wifiOnly;

  bool matches(AvailableRoom room) =>
      (!freeCancellationOnly || room.roomType.refundable) &&
      (!breakfastOnly || room.roomType.breakfastIncluded) &&
      (!wifiOnly || room.roomType.amenities.contains(RoomAmenity.freeWifi));
}
