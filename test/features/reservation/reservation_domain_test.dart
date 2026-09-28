import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';

import 'reservation_test_support.dart';

void main() {
  group('ReservationStatus', () {
    test('every value round-trips through its wire value', () {
      for (final ReservationStatus status in ReservationStatus.values) {
        expect(ReservationStatus.fromWire(status.wireValue), status);
      }
    });

    test('wire values match the Laravel enum', () {
      expect(ReservationStatus.pending.wireValue, 'pending');
      expect(ReservationStatus.depositHeld.wireValue, 'deposit_held');
      expect(ReservationStatus.checkoutInProgress.wireValue,
          'checkout_in_progress');
      expect(ReservationStatus.cancelled.wireValue, 'cancelled');
    });

    test('an unknown wire value falls back to pending', () {
      expect(ReservationStatus.fromWire('nope'), ReservationStatus.pending);
    });

    test('pending is the only awaiting-payment status', () {
      expect(ReservationStatus.pending.isAwaitingPayment, isTrue);
      expect(ReservationStatus.verified.isAwaitingPayment, isFalse);
    });
  });

  group('CreateReservationRequest', () {
    test('fromSelection captures the room type, stay, party and price', () {
      final CreateReservationRequest r = fakeRequest(price: 450);
      expect(r.hotelId, 'oasis');
      expect(r.roomTypeId, 'deluxe');
      expect(r.roomId, isNull);
      expect(r.stay.nights, 2);
      expect(r.party.adults, 2);
      expect(r.guestReference, '+966512345678');
      // 450 / night x 2 nights.
      expect(r.priceSnapshot, const Money(amount: 900));
      expect(r.hotelName.resolve(const Locale('en')), 'The Oasis Hotel');
      expect(r.roomName.resolve(const Locale('en')), 'Deluxe Room');
    });

    test('idempotencyKey is stable and has no time or random component', () {
      final CreateReservationRequest a = fakeRequest();
      final CreateReservationRequest b = fakeRequest();
      expect(a.idempotencyKey, b.idempotencyKey);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different guest or stay yields a different key', () {
      expect(
        fakeRequest(guestReference: '+966500000000').idempotencyKey,
        isNot(fakeRequest().idempotencyKey),
      );
    });
  });
}
