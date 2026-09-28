import 'package:hotel_guest_app/features/discovery/domain/entities/guest_party.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/room_selection.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/room_type_summary.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/stay_range.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';

RoomTypeSummary fakeRoomType({int price = 450}) => RoomTypeSummary(
      id: 'deluxe',
      name: const LocalizedText(ar: 'ديلوكس', en: 'Deluxe Room'),
      description: const LocalizedText(ar: 'وصف', en: 'desc'),
      bedType: const LocalizedText(ar: 'سرير مزدوج', en: 'Double bed'),
      maxOccupancy: 3,
      amenities: const <RoomAmenity>[RoomAmenity.freeWifi],
      nightlyRate: Money(amount: price),
      breakfastIncluded: true,
      refundable: true,
    );

RoomSelection fakeSelection({
  String hotelId = 'oasis',
  int price = 450,
  DateTime? checkIn,
  DateTime? checkOut,
  GuestParty party = const GuestParty(adults: 2, children: 0),
}) {
  return RoomSelection(
    hotelId: hotelId,
    hotelName: const LocalizedText(ar: 'فندق الواحة', en: 'The Oasis Hotel'),
    roomType: fakeRoomType(price: price),
    stay: StayRange(
      checkIn: checkIn ?? DateTime(2026, 9, 6),
      checkOut: checkOut ?? DateTime(2026, 9, 8),
    ),
    party: party,
    nightlyRate: Money(amount: price),
  );
}

CreateReservationRequest fakeRequest({
  String guestReference = '+966512345678',
  int price = 450,
}) =>
    CreateReservationRequest.fromSelection(
      fakeSelection(price: price),
      guestReference: guestReference,
    );
