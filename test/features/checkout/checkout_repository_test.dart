import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/errors/failure.dart';
import 'package:hotel_guest_app/features/checkout/data/datasources/checkout_data_source.dart';
import 'package:hotel_guest_app/features/checkout/data/datasources/dummy_checkout_data_source.dart';
import 'package:hotel_guest_app/features/checkout/data/repositories/checkout_repository_impl.dart';
import 'package:hotel_guest_app/features/checkout/domain/entities/checkout.dart';
import 'package:hotel_guest_app/features/checkout/domain/entities/checkout_status.dart';
import 'package:hotel_guest_app/features/checkout/domain/entities/folio.dart';
import 'package:hotel_guest_app/features/checkout/domain/entities/invoice.dart';
import 'package:hotel_guest_app/features/checkout/domain/repositories/checkout_repository.dart';

import 'checkout_test_support.dart';

class _ThrowingSource implements CheckoutDataSource, InvoiceDataSource {
  const _ThrowingSource(this.error);
  final Object error;
  @override
  Future<Folio> fetchFolio(FolioContext c) async => throw error;
  @override
  Future<CheckoutResult> performCheckout(CheckoutRequest r, FolioContext c) async =>
      throw error;
  @override
  Future<Invoice> fetchInvoice(String r) async => throw error;
}

void main() {
  test('folioFor passes the backend totals through unchanged', () async {
    final id = reservationIdForSettlement(DummySettlementScenario.settles);
    final repo = CheckoutRepositoryImpl(
      DummyCheckoutDataSource(clock: () => DateTime(2026, 9, 8)),
    );
    final folio = await repo.folioFor(fakeFolioContext(reservationId: id));
    expect(folio.chargesTotal.amount, folio.outstandingTotal.amount);
  });

  test('checkout resolves to a CheckoutResult', () async {
    final id = reservationIdForSettlement(DummySettlementScenario.settles);
    final repo = CheckoutRepositoryImpl(
      DummyCheckoutDataSource(clock: () => DateTime(2026, 9, 8)),
    );
    final result = await repo.checkout(
      CheckoutRequest(reservationId: id),
      fakeFolioContext(reservationId: id),
    );
    expect(result.checkout.status, CheckoutStatus.completed);
  });

  test('invoice notFound before checkout becomes a notFound Failure', () async {
    final repo = InvoiceRepositoryImpl(
      DummyCheckoutDataSource(clock: () => DateTime(2026, 9, 8)),
    );
    await expectLater(
      repo.invoiceFor('nope'),
      throwsA(isA<Failure>().having((f) => f.kind, 'kind', FailureKind.notFound)),
    );
  });

  test('a NotImplemented stub becomes a notImplemented Failure', () async {
    final repo = CheckoutRepositoryImpl(
      const _ThrowingSource(NotImplementedInPhaseException('x')),
    );
    await expectLater(
      repo.folioFor(fakeFolioContext()),
      throwsA(isA<Failure>()
          .having((f) => f.kind, 'kind', FailureKind.notImplemented)),
    );
  });

  test('an arbitrary error is mapped to a Failure, not leaked raw', () async {
    final repo =
        CheckoutRepositoryImpl(const _ThrowingSource(FormatException('boom')));
    await expectLater(
      repo.checkout(const CheckoutRequest(reservationId: 'r'), fakeFolioContext()),
      throwsA(isA<Failure>()),
    );
  });
}
