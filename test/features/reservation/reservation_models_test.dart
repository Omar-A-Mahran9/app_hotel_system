import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/guest_party.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/reservation/data/models/reservation_models.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';

import 'reservation_test_support.dart';

void main() {
  const LocalizedText hotelName = LocalizedText(ar: 'الواحة', en: 'Oasis');
  const LocalizedText roomName = LocalizedText(ar: 'ديلوكس', en: 'Deluxe');
  const GuestParty party = GuestParty(adults: 2, children: 1);

  test('ReservationCreatePayload mirrors the documented store fields', () {
    final Map<String, Object?> json =
        ReservationCreatePayload.fromRequest(fakeRequest()).toJson();
    expect(json.keys, containsAll(<String>[
      'room_type_id',
      'room_id',
      'guest_reference',
      'check_in',
      'check_out',
    ]));
    expect(json['room_type_id'], 'deluxe');
    expect(json['room_id'], isNull);
  });

  test('ReservationModel.fromJson maps a ReservationResource-shaped payload', () {
    final ReservationModel model = ReservationModel.fromJson(
      <String, Object?>{
        'id': 4821,
        'reference': 'RSV-482-109',
        'hotel_id': 7,
        'room_type_id': 3,
        'room_id': null,
        'check_in': '2026-09-06T00:00:00.000',
        'check_out': '2026-09-08T00:00:00.000',
        'adults': 2,
        'children': 1,
        'status': 'pending',
        'price_snapshot': '945.00',
        'created_at': '2026-09-08T09:41:00.000',
      },
      hotelName: hotelName,
      roomName: roomName,
      party: party,
    );

    final Reservation entity = model.toEntity();
    expect(entity.id, '4821');
    expect(entity.reference, 'RSV-482-109');
    expect(entity.hotelId, '7');
    expect(entity.roomTypeId, '3');
    expect(entity.roomId, isNull);
    expect(entity.stay.nights, 2);
    expect(entity.party, party);
    expect(entity.status, ReservationStatus.pending);
    // "945.00" decimal string -> 945 whole units.
    expect(entity.priceSnapshot.amount, 945);
    expect(entity.createdAt, DateTime(2026, 9, 8, 9, 41));
    expect(entity.hotelName.resolve(const Locale('en')), 'Oasis');
  });

  test('missing reference derives one from the id', () {
    final ReservationModel model = ReservationModel.fromJson(
      <String, Object?>{
        'id': 99,
        'hotel_id': 1,
        'room_type_id': 1,
        'check_in': '2026-09-06T00:00:00.000',
        'check_out': '2026-09-07T00:00:00.000',
        'status': 'pending',
        'price_snapshot': 300,
      },
      hotelName: hotelName,
      roomName: roomName,
      party: party,
    );
    expect(model.reference, 'RSV-99');
  });
}
