import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/discovery/data/datasources/dummy_discovery_data_source.dart';
import 'package:hotel_guest_app/features/discovery/data/models/discovery_models.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_filters.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/hotel_sort.dart';

void main() {
  const DummyDiscoveryDataSource source = DummyDiscoveryDataSource();

  test('featured hotels are stable and ordered by featured rank', () async {
    final a = await source.fetchFeaturedHotels();
    final b = await source.fetchFeaturedHotels();
    expect(a.map((h) => h.id), b.map((h) => h.id));
    expect(a.first.id, 'oasis');
  });

  test('cities come from the fixture set', () async {
    final cities = await source.fetchCities();
    expect(cities.map((c) => c.id), containsAll(<String>['riyadh', 'jeddah', 'khobar', 'alula']));
  });

  group('searchHotels', () {
    test('empty query returns the whole catalogue', () async {
      final result = await source.searchHotels(
        query: '',
        filters: HotelFilters.none,
        sort: HotelSort.recommended,
      );
      expect(result.totalCount, greaterThanOrEqualTo(8));
      expect(result.hotels.length, result.totalCount);
    });

    test('matches a hotel name in Arabic', () async {
      final result = await source.searchHotels(
        query: 'الواحة',
        filters: HotelFilters.none,
        sort: HotelSort.recommended,
      );
      expect(result.hotels.single.id, 'oasis');
    });

    test('matches a city name in English', () async {
      final result = await source.searchHotels(
        query: 'riyadh',
        filters: HotelFilters.none,
        sort: HotelSort.recommended,
      );
      expect(result.hotels.every((h) => h.cityId == 'riyadh'), isTrue);
      expect(result.hotels, isNotEmpty);
    });

    test('a nonsense query yields no results', () async {
      final result = await source.searchHotels(
        query: 'zzzzz',
        filters: HotelFilters.none,
        sort: HotelSort.recommended,
      );
      expect(result.hotels, isEmpty);
      expect(result.totalCount, 0);
    });

    test('city filter narrows the list', () async {
      final result = await source.searchHotels(
        query: '',
        filters: const HotelFilters(cityIds: <String>{'jeddah'}),
        sort: HotelSort.recommended,
      );
      expect(result.hotels.every((h) => h.cityId == 'jeddah'), isTrue);
    });

    test('price filter narrows the list', () async {
      final result = await source.searchHotels(
        query: '',
        filters: const HotelFilters(priceRange: PriceRange(min: 300, max: 350)),
        sort: HotelSort.recommended,
      );
      expect(
        result.hotels.every((h) =>
            h.nightlyRateFrom.amount >= 300 && h.nightlyRateFrom.amount <= 350),
        isTrue,
      );
    });

    test('priceAsc sort is non-decreasing', () async {
      final result = await source.searchHotels(
        query: '',
        filters: HotelFilters.none,
        sort: HotelSort.priceAsc,
      );
      final prices = result.hotels.map((h) => h.nightlyRateFrom.amount).toList();
      for (int i = 1; i < prices.length; i++) {
        expect(prices[i] >= prices[i - 1], isTrue);
      }
    });

    test('ratingDesc sort is non-increasing and deterministic', () async {
      final a = await source.searchHotels(
        query: '', filters: HotelFilters.none, sort: HotelSort.ratingDesc);
      final b = await source.searchHotels(
        query: '', filters: HotelFilters.none, sort: HotelSort.ratingDesc);
      expect(a.hotels.map((h) => h.id), b.hotels.map((h) => h.id));
      final ratings =
          a.hotels.map((h) => h.rating ?? 0).toList();
      for (int i = 1; i < ratings.length; i++) {
        expect(ratings[i] <= ratings[i - 1], isTrue);
      }
    });
  });

  group('fetchHotel', () {
    test('returns the full hotel for a known id', () async {
      final HotelModel hotel = await source.fetchHotel('oasis');
      expect(hotel.roomTypeCount, 6);
      expect(hotel.facilities, isNotEmpty);
    });

    test('throws NotFoundException for an unknown id', () {
      expect(
        () => source.fetchHotel('does-not-exist'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('fetchAvailability', () {
    final checkIn = DateTime(2026, 9, 6);
    final checkOut = DateTime(2026, 9, 8);

    test('offers room types that fit the party', () async {
      final result = await source.fetchAvailability(
        hotelId: 'oasis',
        checkIn: checkIn,
        checkOut: checkOut,
        adults: 2,
        children: 0,
      );
      expect(result.rooms, isNotEmpty);
      expect(
        result.rooms.every((r) => r.roomType.maxOccupancy >= 2),
        isTrue,
      );
    });

    test('marks a listed-but-sold-out room unavailable (partial result)', () async {
      final result = await source.fetchAvailability(
        hotelId: 'oasis',
        checkIn: checkIn,
        checkOut: checkOut,
        adults: 2,
        children: 0,
      );
      final royal = result.rooms.firstWhere((r) => r.roomType.id == 'royal_suite');
      expect(royal.isAvailable, isFalse);
      expect(result.rooms.any((r) => r.isAvailable), isTrue);
    });

    test('a party larger than every room type yields no rooms', () async {
      final result = await source.fetchAvailability(
        hotelId: 'oasis',
        checkIn: checkIn,
        checkOut: checkOut,
        adults: 6,
        children: 2,
      );
      expect(result.rooms, isEmpty);
    });

    test('is deterministic for the same request', () async {
      final a = await source.fetchAvailability(
        hotelId: 'palm', checkIn: checkIn, checkOut: checkOut, adults: 2, children: 0);
      final b = await source.fetchAvailability(
        hotelId: 'palm', checkIn: checkIn, checkOut: checkOut, adults: 2, children: 0);
      expect(
        a.rooms.map((r) => '${r.roomType.id}:${r.isAvailable}:${r.roomType.nightlyRate.amount}'),
        b.rooms.map((r) => '${r.roomType.id}:${r.isAvailable}:${r.roomType.nightlyRate.amount}'),
      );
    });
  });
}
