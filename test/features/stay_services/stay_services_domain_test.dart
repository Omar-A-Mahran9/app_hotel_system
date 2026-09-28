import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/stay_services/data/fixtures/service_catalogue_fixture.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/hotel_service.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/service_order.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/service_order_status.dart';

import 'stay_services_test_support.dart';

void main() {
  group('ServiceOrderStatus', () {
    test('every value round-trips through its wire value', () {
      for (final ServiceOrderStatus s in ServiceOrderStatus.values) {
        expect(ServiceOrderStatus.fromWire(s.wireValue), s);
      }
    });

    test('wire values match the Laravel ServiceOrder constants', () {
      expect(ServiceOrderStatus.requested.wireValue, 'requested');
      expect(ServiceOrderStatus.confirmed.wireValue, 'confirmed');
      expect(ServiceOrderStatus.fulfilled.wireValue, 'fulfilled');
      expect(ServiceOrderStatus.cancelled.wireValue, 'cancelled');
    });

    test('unknown falls back to requested', () {
      expect(ServiceOrderStatus.fromWire('nope'), ServiceOrderStatus.requested);
    });

    test('terminal + guest-cancellable predicates', () {
      expect(ServiceOrderStatus.fulfilled.isTerminal, isTrue);
      expect(ServiceOrderStatus.cancelled.isTerminal, isTrue);
      expect(ServiceOrderStatus.requested.isTerminal, isFalse);
      expect(ServiceOrderStatus.requested.isGuestCancellable, isTrue);
      // Mirrors ServiceOrderStateMachine: withdrawable until fulfilled.
      expect(ServiceOrderStatus.confirmed.isGuestCancellable, isTrue);
      expect(ServiceOrderStatus.fulfilled.isGuestCancellable, isFalse);
      expect(ServiceOrderStatus.cancelled.isGuestCancellable, isFalse);
      expect(ServiceOrderStatus.requested.isOpen, isTrue);
      expect(ServiceOrderStatus.fulfilled.isOpen, isFalse);
    });
  });

  group('ServiceCatalogue.grouped', () {
    test('groups active services by category, drops inactive', () {
      const cat1 = ServiceCategory(
          id: '1', name: LocalizedText(ar: 'أ', en: 'A'), isActive: true);
      const cat2 = ServiceCategory(
          id: '2', name: LocalizedText(ar: 'ب', en: 'B'), isActive: true);
      HotelService svc(String id, String? catId, {bool active = true}) =>
          HotelService(
            id: id,
            categoryId: catId,
            name: LocalizedText(ar: id, en: id),
            description: const LocalizedText(ar: '', en: ''),
            price: const Money(amount: 0),
            isActive: active,
          );
      const cat = ServiceCatalogue(
        categories: <ServiceCategory>[cat1, cat2],
        services: <HotelService>[],
      );
      final grouped = ServiceCatalogue(
        categories: cat.categories,
        services: <HotelService>[
          svc('a', '1'),
          svc('b', '1', active: false),
          svc('c', '2'),
          svc('d', null),
        ],
      ).grouped();

      expect(grouped.length, 3); // cat1, cat2, uncategorised
      expect(grouped[0].$1?.id, '1');
      expect(grouped[0].$2.map((HotelService s) => s.id), <String>['a']);
      expect(grouped[2].$1, isNull);
      expect(grouped[2].$2.map((HotelService s) => s.id), <String>['d']);
    });

    test('the dummy fixture catalogue is non-empty and deterministic', () {
      final a = ServiceCatalogueFixture.catalogue.grouped();
      final b = ServiceCatalogueFixture.catalogue.grouped();
      expect(a.length, b.length);
      expect(ServiceCatalogueFixture.catalogue.isEmpty, isFalse);
      expect(ServiceCatalogueFixture.serviceById('101')?.name
          .resolve(const Locale('en')), 'Room cleaning');
      expect(ServiceCatalogueFixture.serviceById('999'), isNull);
    });
  });

  group('CreateServiceRequest', () {
    test('idempotency key is stable and has no time / random component', () {
      expect(fakeServiceRequest().idempotencyKey,
          fakeServiceRequest().idempotencyKey);
      expect(fakeServiceRequest(), fakeServiceRequest());
    });

    test('quantity and notes change the key (a different operation)', () {
      expect(fakeServiceRequest(quantity: 2).idempotencyKey,
          isNot(fakeServiceRequest().idempotencyKey));
      expect(fakeServiceRequest(notes: 'hi').idempotencyKey,
          isNot(fakeServiceRequest().idempotencyKey));
    });

    test('forReservation trims blank notes to null', () {
      final r = CreateServiceRequest.forReservation(
        fakeReservation(),
        serviceId: '101',
        serviceName: kRoomCleaning,
        notes: '   ',
      );
      expect(r.notes, isNull);
    });
  });

  group('ServiceOrder', () {
    test('reference is SR-prefixed and cancellable predicate delegates', () {
      final o = ServiceOrder(
        id: '2291',
        reservationId: 'r1',
        serviceId: '101',
        serviceName: kRoomCleaning,
        quantity: 1,
        unitPrice: const Money(amount: 0),
        totalAmount: const Money(amount: 0),
        status: ServiceOrderStatus.requested,
        requestedAt: DateTime(2026, 9, 8),
      );
      expect(o.reference, 'SR-2291');
      expect(o.isGuestCancellable, isTrue);
    });
  });
}
