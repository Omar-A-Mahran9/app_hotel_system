import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/checkout/domain/entities/checkout.dart';
import 'package:hotel_guest_app/features/checkout/domain/entities/checkout_status.dart';
import 'package:hotel_guest_app/features/checkout/domain/entities/folio.dart';
import 'package:hotel_guest_app/features/checkout/domain/entities/invoice.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment_status.dart';

void main() {
  group('CheckoutStatus', () {
    test('round-trips through wire values matching Laravel Checkout', () {
      for (final CheckoutStatus s in CheckoutStatus.values) {
        expect(CheckoutStatus.fromWire(s.wireValue), s);
      }
      expect(CheckoutStatus.inProgress.wireValue, 'in_progress');
      expect(CheckoutStatus.awaitingSettlement.wireValue, 'awaiting_settlement');
      expect(CheckoutStatus.settlementFailed.wireValue, 'settlement_failed');
      expect(CheckoutStatus.completed.wireValue, 'completed');
    });

    test('unknown falls back to inProgress; predicates', () {
      expect(CheckoutStatus.fromWire('?'), CheckoutStatus.inProgress);
      expect(CheckoutStatus.completed.isComplete, isTrue);
      expect(CheckoutStatus.awaitingSettlement.isSettlementPending, isTrue);
      expect(CheckoutStatus.settlementFailed.isSettlementFailed, isTrue);
    });
  });

  group('InvoiceStatus', () {
    test('draft / issued', () {
      expect(InvoiceStatus.fromWire('issued'), InvoiceStatus.issued);
      expect(InvoiceStatus.fromWire('draft'), InvoiceStatus.draft);
      expect(InvoiceStatus.fromWire(null), InvoiceStatus.draft);
      expect(InvoiceStatus.issued.isIssued, isTrue);
    });
  });

  group('CheckoutOutcome', () {
    test('maps every checkout status to a safe outcome', () {
      expect(CheckoutOutcome.fromStatus(CheckoutStatus.completed),
          CheckoutOutcome.completed);
      expect(CheckoutOutcome.fromStatus(CheckoutStatus.awaitingSettlement),
          CheckoutOutcome.settlementPending);
      expect(CheckoutOutcome.fromStatus(CheckoutStatus.settlementFailed),
          CheckoutOutcome.settlementFailed);
    });

    test('success / retryable partition', () {
      expect(CheckoutOutcome.completed.isSuccess, isTrue);
      expect(CheckoutOutcome.settlementFailed.isRetryable, isTrue);
      expect(CheckoutOutcome.settlementPending.isSuccess, isFalse);
      expect(CheckoutOutcome.settlementPending.isRetryable, isFalse);
    });
  });

  group('CheckoutRequest', () {
    test('idempotency key is stable, no time / random', () {
      const a = CheckoutRequest(reservationId: 'r1');
      const b = CheckoutRequest(reservationId: 'r1');
      expect(a.idempotencyKey, 'checkout:r1');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('Folio / Invoice — display only, no client arithmetic', () {
    test('Folio exposes backend totals verbatim and never sums charges', () {
      final folio = Folio(
        reservationId: 'r1',
        currency: 'SAR',
        charges: <FolioCharge>[
          const FolioCharge(
            id: 'a',
            sourceType: 'accommodation',
            description: 'Accommodation',
            quantity: 1,
            unitAmount: Money(amount: 900),
            totalAmount: Money(amount: 900),
            status: 'posted',
          ),
          const FolioCharge(
            id: 'b',
            sourceType: 'service_order',
            description: 'x',
            quantity: 1,
            unitAmount: Money(amount: 45),
            totalAmount: Money(amount: 45),
            status: 'cancelled',
          ),
        ],
        // Deliberately NOT 945 — the backend says the total is 900 (the
        // cancelled line doesn't count) and the app must trust that.
        chargesTotal: const Money(amount: 900),
        paymentsTotal: const Money(amount: 0),
        outstandingTotal: const Money(amount: 900),
      );
      expect(folio.chargesTotal.amount, 900);
      expect(folio.postedCharges, hasLength(1));
      expect(folio.hasOutstanding, isTrue);
    });

    test('Invoice reports settled purely from its outstanding total', () {
      Invoice inv(int outstanding) => Invoice(
            id: '1',
            reservationId: 'r1',
            invoiceNumber: 'INV-1',
            status: InvoiceStatus.issued,
            currency: 'SAR',
            subtotal: const Money(amount: 1065),
            paymentsTotal: const Money(amount: 1065),
            outstandingTotal: Money(amount: outstanding),
            items: const <InvoiceItem>[],
          );
      expect(inv(0).isSettled, isTrue);
      expect(inv(50).isSettled, isFalse);
    });
  });

  group('CheckoutResult', () {
    test('carries the settlement status separately, not collapsed', () {
      final checkout = Checkout(
        reservationId: 'r1',
        status: CheckoutStatus.completed,
        chargesTotal: const Money(amount: 1065),
        paymentsTotal: const Money(amount: 0),
        outstandingTotal: const Money(amount: 0),
        currency: 'SAR',
      );
      final result = CheckoutResult.of(
        checkout,
        settlementStatus: PaymentStatus.settled,
        invoice: const InvoiceRef(
          id: '9',
          invoiceNumber: 'INV-9',
          status: InvoiceStatus.issued,
        ),
      );
      expect(result.outcome, CheckoutOutcome.completed);
      expect(result.settlementStatus, PaymentStatus.settled);
      expect(result.invoice!.invoiceNumber, 'INV-9');
    });
  });
}
