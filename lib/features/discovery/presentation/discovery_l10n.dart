import '../../../core/localization/l10n.dart';
import '../domain/entities/hotel.dart';
import '../domain/entities/hotel_sort.dart';
import '../domain/entities/room_sort.dart';
import '../domain/entities/room_type_summary.dart';
import '../domain/validators/stay_dates_validator.dart';

/// Localized labels for the discovery feature's enums. Keeps the enum → string
/// mapping in one place instead of scattering `switch`es through widgets.
extension DiscoveryL10n on AppLocalizations {
  String hotelAmenityLabel(HotelAmenity amenity) => switch (amenity) {
        HotelAmenity.freeWifi => amenityFreeWifi,
        HotelAmenity.breakfast => amenityBreakfast,
        HotelAmenity.parking => amenityParking,
        HotelAmenity.pool => amenityPool,
        HotelAmenity.gym => amenityGym,
        HotelAmenity.familyRooms => amenityFamilyRooms,
        HotelAmenity.airportShuttle => amenityAirportShuttle,
        HotelAmenity.roomService => amenityRoomService,
      };

  String roomAmenityLabel(RoomAmenity amenity) => switch (amenity) {
        RoomAmenity.freeWifi => amenityFreeWifi,
        RoomAmenity.airConditioning => amenityAirConditioning,
        RoomAmenity.cityView => amenityCityView,
        RoomAmenity.balcony => amenityBalcony,
        RoomAmenity.kitchenette => amenityKitchenette,
      };

  String hotelSortLabel(HotelSort sort) => switch (sort) {
        HotelSort.recommended => sortRecommended,
        HotelSort.ratingDesc => sortTopRated,
        HotelSort.priceAsc => sortLowestPrice,
      };

  String roomSortLabel(RoomSort sort) => switch (sort) {
        RoomSort.priceAsc => roomsSortLowest,
        RoomSort.priceDesc => roomsSortHighest,
      };

  String? stayDatesErrorLabel(StayDatesError? error) => switch (error) {
        null => null,
        StayDatesError.incomplete => null,
        StayDatesError.checkOutNotAfterCheckIn =>
          stayDatesErrorCheckoutBeforeCheckin,
        StayDatesError.checkInInPast => stayDatesErrorPast,
      };
}
