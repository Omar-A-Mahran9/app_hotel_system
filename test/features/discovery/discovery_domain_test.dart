import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/availability_request.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/available_room.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/guest_party.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_filters.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/room_selection.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/room_type_summary.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/stay_range.dart';
import 'package:hotel_guest_app/features/discovery/domain/validators/stay_dates_validator.dart';

RoomTypeSummary _roomType({int price = 320, int occupancy = 2}) => RoomTypeSummary(
      id: 'standard',
      name: const LocalizedText(ar: 'قياسية', en: 'Standard'),
      description: const LocalizedText(ar: 'وصف', en: 'desc'),
      bedType: const LocalizedText(ar: 'مزدوج', en: 'Double'),
      maxOccupancy: occupancy,
      amenities: const <RoomAmenity>[RoomAmenity.freeWifi],
      nightlyRate: Money(amount: price),
      breakfastIncluded: true,
      refundable: true,
    );

void main() {
  group('LocalizedText', () {
    const LocalizedText text = LocalizedText(ar: 'فندق', en: 'Hotel');

    test('resolves Arabic for the ar locale', () {
      expect(text.resolve(const Locale('ar')), 'فندق');
    });

    test('falls back to English for anything else', () {
      expect(text.resolve(const Locale('en')), 'Hotel');
      expect(text.resolve(const Locale('fr')), 'Hotel');
    });
  });

  group('Money', () {
    test('multiplies by nights', () {
      expect(const Money(amount: 320) * 3, const Money(amount: 960));
    });

    test('equality is value based', () {
      expect(const Money(amount: 100), const Money(amount: 100));
      expect(const Money(amount: 100) == const Money(amount: 101), isFalse);
    });
  });

  group('HotelFilters', () {
    test('none is inactive', () {
      expect(HotelFilters.none.isActive, isFalse);
      expect(HotelFilters.none.activeCount, 0);
    });

    test('toggleCity adds then removes', () {
      final HotelFilters once = HotelFilters.none.toggleCity('riyadh');
      expect(once.cityIds, <String>{'riyadh'});
      expect(once.isActive, isTrue);
      expect(once.toggleCity('riyadh').cityIds, isEmpty);
    });

    test('activeCount counts city and price independently', () {
      const HotelFilters both = HotelFilters(
        cityIds: <String>{'jeddah'},
        priceRange: PriceRange(min: 300, max: 900),
      );
      expect(both.activeCount, 2);
    });

    test('clearPriceRange drops the range', () {
      const HotelFilters withPrice =
          HotelFilters(priceRange: PriceRange(min: 1, max: 2));
      expect(withPrice.copyWith(clearPriceRange: true).priceRange, isNull);
    });

    test('equality ignores set order', () {
      expect(
        const HotelFilters(cityIds: <String>{'a', 'b'}),
        const HotelFilters(cityIds: <String>{'b', 'a'}),
      );
    });
  });

  group('PriceRange', () {
    test('contains is inclusive', () {
      const PriceRange range = PriceRange(min: 300, max: 900);
      expect(range.contains(300), isTrue);
      expect(range.contains(900), isTrue);
      expect(range.contains(901), isFalse);
    });
  });

  group('StayRange', () {
    test('nights is the day difference and time is stripped', () {
      final StayRange range = StayRange(
        checkIn: DateTime(2026, 9, 6, 15),
        checkOut: DateTime(2026, 9, 8, 11),
      );
      expect(range.nights, 2);
      expect(range.checkIn, DateTime(2026, 9, 6));
    });

    test('a same-day or reversed range fails the invariant assert', () {
      expect(
        () => StayRange(
          checkIn: DateTime(2026, 9, 8),
          checkOut: DateTime(2026, 9, 8),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('tryCreate returns null for invalid input, a range for valid', () {
      expect(StayRange.tryCreate(checkIn: DateTime(2026, 9, 8), checkOut: null),
          isNull);
      expect(
        StayRange.tryCreate(
          checkIn: DateTime(2026, 9, 8),
          checkOut: DateTime(2026, 9, 8),
        ),
        isNull,
      );
      expect(
        StayRange.tryCreate(
          checkIn: DateTime(2026, 9, 6),
          checkOut: DateTime(2026, 9, 8),
        )?.nights,
        2,
      );
    });
  });

  group('AvailabilityRequest', () {
    AvailabilityRequest req({String hotel = 'oasis', GuestParty? party}) =>
        AvailabilityRequest(
          hotelId: hotel,
          stay: StayRange(
            checkIn: DateTime(2026, 9, 6),
            checkOut: DateTime(2026, 9, 8),
          ),
          party: party ?? GuestParty.initial,
        );

    test('value equality over hotel, stay and party', () {
      expect(req(), req());
      expect(req(hotel: 'palm') == req(), isFalse);
      expect(
        req(party: const GuestParty(adults: 3, children: 0)) == req(),
        isFalse,
      );
    });
  });

  group('RoomSelection', () {
    final StayRange stay = StayRange(
      checkIn: DateTime(2026, 9, 6),
      checkOut: DateTime(2026, 9, 8),
    );
    const GuestParty party = GuestParty(adults: 2, children: 0);

    RoomSelection selection() => RoomSelection.fromAvailableRoom(
          room: AvailableRoom(roomType: _roomType(price: 450), isAvailable: true),
          hotelId: 'oasis',
          hotelName: const LocalizedText(ar: 'الواحة', en: 'Oasis'),
          stay: stay,
          party: party,
        );

    test('fromAvailableRoom snapshots the room type, price, stay and party', () {
      final RoomSelection sel = selection();
      expect(sel.hotelId, 'oasis');
      expect(sel.roomTypeId, 'standard');
      expect(sel.nightlyRate, const Money(amount: 450));
      expect(sel.nights, 2);
      expect(sel.roomId, isNull); // physical room not modelled yet
    });

    test('stayTotal is integer nightly rate times nights', () {
      expect(selection().stayTotal, const Money(amount: 900));
    });

    test('matches only its own hotel, stay and party', () {
      final RoomSelection sel = selection();
      expect(
        sel.matches(AvailabilityRequest(hotelId: 'oasis', stay: stay, party: party)),
        isTrue,
      );
      expect(
        sel.matches(AvailabilityRequest(hotelId: 'palm', stay: stay, party: party)),
        isFalse,
      );
      expect(
        sel.matches(AvailabilityRequest(
          hotelId: 'oasis',
          stay: StayRange(
            checkIn: DateTime(2026, 9, 6),
            checkOut: DateTime(2026, 9, 9),
          ),
          party: party,
        )),
        isFalse,
      );
      expect(
        sel.matches(AvailabilityRequest(
          hotelId: 'oasis',
          stay: stay,
          party: const GuestParty(adults: 3, children: 0),
        )),
        isFalse,
      );
    });

    test('copyWith carries a physical room id', () {
      expect(selection().copyWith(roomId: 'r-101').roomId, 'r-101');
    });
  });

  group('StayDatesValidator', () {
    final DateTime today = DateTime(2026, 9, 1);

    test('incomplete when a date is missing', () {
      expect(
        StayDatesValidator.validate(checkIn: today, checkOut: null),
        StayDatesError.incomplete,
      );
    });

    test('rejects check-out on or before check-in', () {
      expect(
        StayDatesValidator.validate(
          checkIn: DateTime(2026, 9, 8),
          checkOut: DateTime(2026, 9, 8),
        ),
        StayDatesError.checkOutNotAfterCheckIn,
      );
    });

    test('rejects a check-in before the minimum date', () {
      expect(
        StayDatesValidator.validate(
          checkIn: DateTime(2026, 8, 30),
          checkOut: DateTime(2026, 9, 2),
          minDate: today,
        ),
        StayDatesError.checkInInPast,
      );
    });

    test('accepts a valid forward range and builds it', () {
      final StayRange? range = StayDatesValidator.toRange(
        checkIn: DateTime(2026, 9, 6),
        checkOut: DateTime(2026, 9, 8),
        minDate: today,
      );
      expect(range, isNotNull);
      expect(range!.nights, 2);
    });
  });

  group('GuestParty', () {
    test('initial is two adults', () {
      expect(GuestParty.initial, const GuestParty(adults: 2, children: 0));
      expect(GuestParty.initial.total, 2);
    });

    test('copyWith clamps to the bounds', () {
      expect(GuestParty.initial.copyWith(adults: 0).adults, GuestParty.minAdults);
      expect(
        GuestParty.initial.copyWith(children: 99).children,
        GuestParty.maxChildren,
      );
    });
  });

  group('AvailableRoom', () {
    final RoomTypeSummary type = RoomTypeSummary(
      id: 'standard',
      name: const LocalizedText(ar: 'قياسية', en: 'Standard'),
      description: const LocalizedText(ar: '', en: ''),
      bedType: const LocalizedText(ar: '', en: ''),
      maxOccupancy: 2,
      amenities: const <RoomAmenity>[],
      nightlyRate: const Money(amount: 320),
      breakfastIncluded: true,
      refundable: true,
    );

    test('stayTotal multiplies the nightly rate', () {
      final AvailableRoom room = AvailableRoom(roomType: type, isAvailable: true);
      expect(room.stayTotal(3), const Money(amount: 960));
    });
  });
}
