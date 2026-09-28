import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/payment/data/datasources/dummy_payment_data_source.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment_status.dart';

import 'payment_test_support.dart';

void main() {
  final DateTime fixedNow = DateTime(2026, 9, 8, 9, 41);

  group('DummyPaymentDataSource', () {
    DummyPaymentDataSource source() => DummyPaymentDataSource(clock: () => fixedNow);

    test('scenario is a pure function of the reservation id', () {
      final id = reservationIdForScenario(DummyHoldScenario.succeeds);
      expect(DummyPaymentDataSource.scenarioFor(id), DummyHoldScenario.succeeds);
      expect(DummyPaymentDataSource.scenarioFor(id), DummyHoldScenario.succeeds);
    });

    test('"succeeds" scenario goes HOLD_ACTIVE on the first hold', () async {
      final id = reservationIdForScenario(DummyHoldScenario.succeeds);
      final m = await source().requestHold(fakeHoldRequest(reservationId: id));
      expect(m.toEntity().status, PaymentStatus.holdActive);
    });

    test('"staysPending" scenario stays HOLD_REQUESTED', () async {
      final id = reservationIdForScenario(DummyHoldScenario.staysPending);
      final m = await source().requestHold(fakeHoldRequest(reservationId: id));
      expect(m.toEntity().status, PaymentStatus.holdRequested);
    });

    test('"failsThenSucceeds" fails first, then a retry with the same key '
        'succeeds', () async {
      final id = reservationIdForScenario(DummyHoldScenario.failsThenSucceeds);
      final s = source();
      final first = await s.requestHold(fakeHoldRequest(reservationId: id));
      expect(first.toEntity().status, PaymentStatus.holdFailed);

      final retry = await s.requestHold(fakeHoldRequest(reservationId: id));
      expect(retry.toEntity().status, PaymentStatus.holdActive);
    });

    test('a duplicate hold of a successful request does not run a second '
        'operation', () async {
      final id = reservationIdForScenario(DummyHoldScenario.succeeds);
      final s = source();
      final a = await s.requestHold(fakeHoldRequest(reservationId: id));
      final b = await s.requestHold(fakeHoldRequest(reservationId: id));
      expect(a.toEntity().id, b.toEntity().id);
    });

    test('fetchForReservation returns null until a hold is placed', () async {
      final id = reservationIdForScenario(DummyHoldScenario.succeeds);
      final s = source();
      expect(await s.fetchForReservation(id), isNull);
      await s.requestHold(fakeHoldRequest(reservationId: id));
      expect(await s.fetchForReservation(id), isNotNull);
    });

    test('failWith seam surfaces an error from both methods', () async {
      final s = source()..failWith = const NetworkException();
      await expectLater(
          s.requestHold(fakeHoldRequest()), throwsA(isA<NetworkException>()));
      await expectLater(
          s.fetchForReservation('x'), throwsA(isA<NetworkException>()));
    });
  });

  // `ApiPaymentDataSource` is now a real implementation against the guest
  // payment endpoints — see
  // test/features/payment/api_payment_data_source_test.dart.
}
