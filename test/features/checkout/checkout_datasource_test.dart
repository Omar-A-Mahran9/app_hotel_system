import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/checkout/data/datasources/dummy_checkout_data_source.dart';
import 'package:hotel_guest_app/features/checkout/domain/entities/checkout.dart';
import 'package:hotel_guest_app/features/checkout/domain/entities/checkout_status.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment_status.dart';

import 'checkout_test_support.dart';

void main() {
  final DateTime now = DateTime(2026, 9, 8, 11);

  group('DummyCheckoutDataSource — folio', () {
    DummyCheckoutDataSource source() => DummyCheckoutDataSource(clock: () => now);

    test('accommodation charge equals the reservation price snapshot', () async {
      final folio =
          await source().fetchFolio(fakeFolioContext(accommodationAmount: 900));
      final acc = folio.charges.firstWhere((c) => c.isAccommodation);
      expect(acc.totalAmount.amount, 900);
    });

    test('charges total is the folio sum (computed once, backend DTO shape); '
        'payments total is 0 (a deposit hold is not captured money)', () async {
      final id = reservationIdForSettlement(DummySettlementScenario.settles);
      final folio = await source()
          .fetchFolio(fakeFolioContext(reservationId: id, accommodationAmount: 900));
      final num sum =
          folio.charges.fold<num>(0, (num s, c) => s + c.totalAmount.amount);
      expect(folio.chargesTotal.amount, sum);
      expect(folio.paymentsTotal.amount, 0);
      expect(folio.outstandingTotal.amount, sum);
    });

    test('the folio is deterministic per reservation id', () async {
      final ctx = fakeFolioContext(reservationId: 'kX');
      final a = await source().fetchFolio(ctx);
      final b = await source().fetchFolio(ctx);
      expect(a.chargesTotal, b.chargesTotal);
      expect(a.charges.length, b.charges.length);
    });
  });

  group('DummyCheckoutDataSource — checkout', () {
    DummyCheckoutDataSource source() => DummyCheckoutDataSource(clock: () => now);

    test('"settles" scenario completes and issues an invoice', () async {
      final id = reservationIdForSettlement(DummySettlementScenario.settles);
      final s = source();
      final result = await s.performCheckout(
        CheckoutRequest(reservationId: id),
        fakeFolioContext(reservationId: id),
      );
      expect(result.checkout.status, CheckoutStatus.completed);
      expect(result.checkout.outstandingTotal.amount, 0);
      expect(result.invoice, isNotNull);
      expect(result.settlementStatus, PaymentStatus.settled);

      final invoice = await s.fetchInvoice(id);
      expect(invoice.isIssued, isTrue);
      expect(invoice.outstandingTotal.amount, 0);
      expect(invoice.items, isNotEmpty);
    });

    test('"staysPending" scenario stays awaiting_settlement, no invoice yet',
        () async {
      final id = reservationIdForSettlement(DummySettlementScenario.staysPending);
      final s = source();
      final result = await s.performCheckout(
        CheckoutRequest(reservationId: id),
        fakeFolioContext(reservationId: id),
      );
      expect(result.checkout.status, CheckoutStatus.awaitingSettlement);
      expect(result.settlementStatus, PaymentStatus.captureRequested);
      await expectLater(
          s.fetchInvoice(id), throwsA(isA<NotFoundException>()));
    });

    test('"failsThenSettles": fails first, then a retry with the same key '
        'completes', () async {
      final id =
          reservationIdForSettlement(DummySettlementScenario.failsThenSettles);
      final s = source();
      final first = await s.performCheckout(
        CheckoutRequest(reservationId: id),
        fakeFolioContext(reservationId: id),
      );
      expect(first.checkout.status, CheckoutStatus.settlementFailed);
      expect(first.settlementStatus, PaymentStatus.captureFailed);

      final retry = await s.performCheckout(
        CheckoutRequest(reservationId: id),
        fakeFolioContext(reservationId: id),
      );
      expect(retry.checkout.status, CheckoutStatus.completed);
    });

    test('a duplicate checkout of a completed reservation replays', () async {
      final id = reservationIdForSettlement(DummySettlementScenario.settles);
      final s = source();
      final a = await s.performCheckout(
          CheckoutRequest(reservationId: id), fakeFolioContext(reservationId: id));
      final b = await s.performCheckout(
          CheckoutRequest(reservationId: id), fakeFolioContext(reservationId: id));
      expect(a.invoice!.invoiceNumber, b.invoice!.invoiceNumber);
    });

    test('fetchInvoice before checkout is a NotFound', () async {
      await expectLater(
          source().fetchInvoice('never'), throwsA(isA<NotFoundException>()));
    });

    test('failWith seam surfaces an error from every method', () async {
      final s = source()..failWith = const NetworkException();
      await expectLater(
          s.fetchFolio(fakeFolioContext()), throwsA(isA<NetworkException>()));
      await expectLater(
        s.performCheckout(
            const CheckoutRequest(reservationId: 'x'), fakeFolioContext()),
        throwsA(isA<NetworkException>()),
      );
      await expectLater(
          s.fetchInvoice('x'), throwsA(isA<NetworkException>()));
    });
  });

  // `ApiCheckoutDataSource` is now a real implementation against the guest
  // checkout/invoice endpoints — see
  // test/features/checkout/api_checkout_data_source_test.dart.
}
