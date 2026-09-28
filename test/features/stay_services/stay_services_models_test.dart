import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/stay_services/data/models/stay_services_models.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/service_order_status.dart';

import 'stay_services_test_support.dart';

void main() {
  test('ServiceOrderCreatePayload mirrors the documented store fields', () {
    final json = ServiceOrderCreatePayload.fromRequest(
      fakeServiceRequest(serviceId: '102', quantity: 2, notes: 'no ice'),
    ).toJson();
    expect(json.keys, containsAll(<String>['service_id', 'quantity', 'notes']));
    expect(json['service_id'], 102);
    expect(json['quantity'], 2);
    expect(json['notes'], 'no ice');
  });

  test('ServiceOrderModel.fromJson maps a ServiceOrderResource payload', () {
    final model = ServiceOrderModel.fromJson(<String, Object?>{
      'id': 2291,
      'reservation_id': 7,
      'service_id': 102,
      'quantity': 2,
      'unit_price_snapshot': '30.00',
      'currency_snapshot': 'SAR',
      'total_amount': '60.00',
      'status': 'confirmed',
      'notes': 'no ice',
      'requested_at': '2026-09-08T09:41:00.000',
      'confirmed_at': '2026-09-08T09:43:00.000',
    });
    final entity =
        model.toEntity(serviceName: const LocalizedText(ar: 'خدمة', en: 'svc'));
    expect(entity.id, '2291');
    expect(entity.reservationId, '7');
    expect(entity.quantity, 2);
    // Authoritative snapshot values — not recomputed by the app.
    expect(entity.unitPrice.amount, 30);
    expect(entity.totalAmount.amount, 60);
    expect(entity.status, ServiceOrderStatus.confirmed);
    expect(entity.reference, 'SR-2291');
    expect(entity.serviceName.resolve(const Locale('ar')), 'خدمة');
  });

  test('an unknown status maps to requested defensively', () {
    final model = ServiceOrderModel.fromJson(<String, Object?>{
      'id': 1,
      'reservation_id': 1,
      'service_id': 1,
      'status': 'weird',
      'total_amount': '0.00',
    });
    expect(
      model.toEntity(serviceName: const LocalizedText(ar: 'x', en: 'x')).status,
      ServiceOrderStatus.requested,
    );
  });
}
