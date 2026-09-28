import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment_request.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment_result.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment_status.dart';

import 'payment_test_support.dart';

void main() {
  group('PaymentStatus', () {
    test('every value round-trips through its wire value', () {
      for (final PaymentStatus s in PaymentStatus.values) {
        expect(PaymentStatus.fromWire(s.wireValue), s);
      }
    });

    test('wire values match the Laravel Payment constants', () {
      expect(PaymentStatus.notStarted.wireValue, 'not_started');
      expect(PaymentStatus.holdActive.wireValue, 'hold_active');
      expect(PaymentStatus.finalSettlementRequested.wireValue,
          'final_settlement_requested');
      expect(PaymentStatus.settled.wireValue, 'settled');
    });

    test('an unknown wire value falls back to notStarted', () {
      expect(PaymentStatus.fromWire('nope'), PaymentStatus.notStarted);
    });

    test('terminal statuses mirror the state machine', () {
      expect(PaymentStatus.settled.isTerminal, isTrue);
      expect(PaymentStatus.cancelled.isTerminal, isTrue);
      expect(PaymentStatus.expired.isTerminal, isTrue);
      expect(PaymentStatus.refunded.isTerminal, isTrue);
      expect(PaymentStatus.holdActive.isTerminal, isFalse);
      expect(PaymentStatus.holdRequested.isTerminal, isFalse);
    });

    test('secured is a positive list (hold / capture / settlement)', () {
      expect(PaymentStatus.holdActive.isSecured, isTrue);
      expect(PaymentStatus.captured.isSecured, isTrue);
      expect(PaymentStatus.settled.isSecured, isTrue);
      expect(PaymentStatus.holdRequested.isSecured, isFalse);
      expect(PaymentStatus.holdFailed.isSecured, isFalse);
      expect(PaymentStatus.notStarted.isSecured, isFalse);
    });

    test('canRequestHold only from notStarted / holdFailed', () {
      expect(PaymentStatus.notStarted.canRequestHold, isTrue);
      expect(PaymentStatus.holdFailed.canRequestHold, isTrue);
      expect(PaymentStatus.holdActive.canRequestHold, isFalse);
    });
  });

  group('PaymentHoldRequest', () {
    test('carries the reservation price snapshot, decimal wire amount', () {
      final r = fakeHoldRequest(amount: 900);
      expect(r.amountWire, '900.00');
      expect(r.currencyWire, 'SAR');
    });

    test('idempotencyKey is stable and has no time / random component', () {
      expect(fakeHoldRequest().idempotencyKey, fakeHoldRequest().idempotencyKey);
      expect(fakeHoldRequest(), fakeHoldRequest());
      expect(fakeHoldRequest().hashCode, fakeHoldRequest().hashCode);
    });

    test('a different reservation or amount yields a different key', () {
      expect(fakeHoldRequest(reservationId: 'x').idempotencyKey,
          isNot(fakeHoldRequest().idempotencyKey));
      expect(fakeHoldRequest(amount: 5).idempotencyKey,
          isNot(fakeHoldRequest().idempotencyKey));
    });

    test('forReservation uses the reservation id + price snapshot', () {
      final r =
          PaymentHoldRequest.forReservation(fakeReservation(id: 'res-9', amount: 450));
      expect(r.reservationId, 'res-9');
      expect(r.amount, const Money(amount: 450));
    });

    test('never carries card / credential fields', () {
      // The type only exposes reservationId + amount — a compile-time guarantee
      // reflected here so a future field addition is a conscious change.
      final r = fakeHoldRequest();
      expect(r.toString().toLowerCase(), isNot(contains('card')));
      expect(r.toString().toLowerCase(), isNot(contains('cvv')));
    });
  });

  group('PaymentResult / PaymentOutcome', () {
    test('maps every status to a safe outcome', () {
      expect(PaymentOutcome.fromStatus(PaymentStatus.holdActive),
          PaymentOutcome.held);
      expect(PaymentOutcome.fromStatus(PaymentStatus.holdRequested),
          PaymentOutcome.pending);
      expect(PaymentOutcome.fromStatus(PaymentStatus.holdFailed),
          PaymentOutcome.failed);
      expect(PaymentOutcome.fromStatus(PaymentStatus.cancelled),
          PaymentOutcome.cancelled);
      expect(PaymentOutcome.fromStatus(PaymentStatus.expired),
          PaymentOutcome.expired);
      expect(PaymentOutcome.fromStatus(PaymentStatus.settled),
          PaymentOutcome.held);
    });

    test('isSuccess / isRetryable partition the outcomes', () {
      expect(PaymentOutcome.held.isSuccess, isTrue);
      expect(PaymentOutcome.pending.isSuccess, isFalse);
      expect(PaymentOutcome.failed.isRetryable, isTrue);
      expect(PaymentOutcome.cancelled.isRetryable, isTrue);
      expect(PaymentOutcome.expired.isRetryable, isTrue);
      expect(PaymentOutcome.held.isRetryable, isFalse);
    });

    test('PaymentResult.of derives the outcome from the payment status', () {
      final payment = Payment(
        id: '1',
        reservationId: 'res-1',
        hotelId: 'h',
        status: PaymentStatus.holdActive,
        amount: const Money(amount: 900),
        createdAt: DateTime(2026, 9, 1),
      );
      expect(PaymentResult.of(payment).outcome, PaymentOutcome.held);
    });
  });

  group('Payment.none', () {
    test('is a NOT_STARTED synthetic record that does not "exist"', () {
      final p = Payment.none(
        reservationId: 'res-1',
        hotelId: 'oasis',
        amount: const Money(amount: 900),
      );
      expect(p.status, PaymentStatus.notStarted);
      expect(p.exists, isFalse);
    });
  });
}
