import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/payment/data/models/payment_models.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment_status.dart';

import 'payment_test_support.dart';

void main() {
  test('PaymentHoldPayload mirrors the documented store fields', () {
    final json = PaymentHoldPayload.fromRequest(fakeHoldRequest(amount: 900)).toJson();
    expect(json.keys, containsAll(<String>['amount', 'currency']));
    expect(json['amount'], '900.00');
    expect(json['currency'], 'SAR');
    expect(json.containsKey('idempotency_key'), isFalse,
        reason: 'the idempotency key is an HTTP header, never a body field');
  });

  test('PaymentModel.fromJson maps a PaymentResource-shaped payload', () {
    final model = PaymentModel.fromJson(<String, Object?>{
      'id': 42,
      'reservation_id': 7,
      'hotel_id': 3,
      'status': 'hold_active',
      'amount': '945.00',
      'currency': 'SAR',
      'hold_expires_at': '2026-09-02T00:00:00.000',
      'created_at': '2026-09-01T09:41:00.000',
      'updated_at': '2026-09-01T09:41:05.000',
    });
    final entity = model.toEntity();
    expect(entity.id, '42');
    expect(entity.reservationId, '7');
    expect(entity.hotelId, '3');
    expect(entity.status, PaymentStatus.holdActive);
    expect(entity.amount.amount, 945);
    expect(entity.amount.currency, 'SAR');
    expect(entity.holdExpiresAt, DateTime(2026, 9, 2));
    expect(entity.exists, isTrue);
  });

  test('a null id / missing fields degrade safely', () {
    final model = PaymentModel.fromJson(<String, Object?>{
      'id': null,
      'reservation_id': 7,
      'hotel_id': 3,
      'status': 'hold_failed',
      'amount': 0,
    });
    final entity = model.toEntity();
    expect(entity.exists, isFalse);
    expect(entity.status, PaymentStatus.holdFailed);
  });

  test('an unknown status maps to notStarted defensively', () {
    final model = PaymentModel.fromJson(<String, Object?>{
      'id': 1,
      'reservation_id': 1,
      'hotel_id': 1,
      'status': 'wat',
      'amount': '10.00',
    });
    expect(model.toEntity().status, PaymentStatus.notStarted);
  });
}
