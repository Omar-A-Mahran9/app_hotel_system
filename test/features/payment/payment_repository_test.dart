import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/errors/failure.dart';
import 'package:hotel_guest_app/features/payment/data/datasources/dummy_payment_data_source.dart';
import 'package:hotel_guest_app/features/payment/data/datasources/payment_data_source.dart';
import 'package:hotel_guest_app/features/payment/data/models/payment_models.dart';
import 'package:hotel_guest_app/features/payment/data/repositories/payment_repository_impl.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment_request.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment_result.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment_status.dart';

import 'payment_test_support.dart';

class _ThrowingSource implements PaymentDataSource {
  const _ThrowingSource(this.error);
  final Object error;

  @override
  Future<PaymentModel?> fetchForReservation(String reservationId) async =>
      throw error;

  @override
  Future<PaymentModel> requestHold(PaymentHoldRequest request) async =>
      throw error;
}

void main() {
  test('maps a resolved hold to a PaymentResult', () async {
    final id = reservationIdForScenario(DummyHoldScenario.succeeds);
    final repo = PaymentRepositoryImpl(
      DummyPaymentDataSource(clock: () => DateTime(2026, 9, 8)),
    );
    final PaymentResult result =
        await repo.requestHold(fakeHoldRequest(reservationId: id));
    expect(result.outcome, PaymentOutcome.held);
    expect(result.status, PaymentStatus.holdActive);
  });

  test('currentForReservation returns a synthetic none when there is no hold',
      () async {
    final repo = PaymentRepositoryImpl(
      DummyPaymentDataSource(clock: () => DateTime(2026, 9, 8)),
    );
    final payment = await repo.currentForReservation('res-x');
    expect(payment.exists, isFalse);
    expect(payment.status, PaymentStatus.notStarted);
  });

  test('a NotImplemented stub becomes a notImplemented Failure', () async {
    final repo =
        PaymentRepositoryImpl(const _ThrowingSource(NotImplementedInPhaseException('x')));
    await expectLater(
      repo.requestHold(fakeHoldRequest()),
      throwsA(isA<Failure>()
          .having((f) => f.kind, 'kind', FailureKind.notImplemented)),
    );
  });

  test('an arbitrary error is mapped to a Failure, not leaked raw', () async {
    final repo = PaymentRepositoryImpl(const _ThrowingSource(FormatException('boom')));
    await expectLater(repo.requestHold(fakeHoldRequest()), throwsA(isA<Failure>()));
  });

  test('a network error becomes a retryable network Failure', () async {
    final repo = PaymentRepositoryImpl(const _ThrowingSource(NetworkException()));
    await expectLater(
      repo.currentForReservation('x'),
      throwsA(isA<Failure>().having((f) => f.kind, 'kind', FailureKind.network)),
    );
  });
}
