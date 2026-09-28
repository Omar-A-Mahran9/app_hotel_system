import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/checkout/data/models/checkout_models.dart';
import 'package:hotel_guest_app/features/checkout/domain/entities/checkout_status.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment_status.dart';

void main() {
  test('FolioModel maps a FolioResource payload; totals come from the wire', () {
    final folio = FolioModel(<String, Object?>{
      'reservation': <String, Object?>{'id': 7},
      'currency': 'SAR',
      'charges': <Object?>[
        <String, Object?>{
          'id': 1,
          'source_type': 'accommodation',
          'description': 'Accommodation',
          'quantity': 1,
          'unit_amount': '900.00',
          'total_amount': '900.00',
          'status': 'posted',
        },
        <String, Object?>{
          'id': 2,
          'source_type': 'service_order',
          'description': 'Laundry',
          'quantity': 1,
          'unit_amount': '45.00',
          'total_amount': '45.00',
          'status': 'posted',
        },
      ],
      'totals': <String, Object?>{
        'charges_total': '945.00',
        'payments_total': '0.00',
        'outstanding_total': '945.00',
      },
    }).toEntity();

    expect(folio.reservationId, '7');
    expect(folio.charges, hasLength(2));
    expect(folio.chargesTotal.amount, 945);
    expect(folio.outstandingTotal.amount, 945);
    expect(folio.postedCharges, hasLength(2));
  });

  test('CheckoutResultModel maps a CheckoutResource payload', () {
    final result = CheckoutResultModel(<String, Object?>{
      'reservation': <String, Object?>{'id': 7, 'status': 'invoiced'},
      'checkout': <String, Object?>{
        'status': 'completed',
        'completed_at': '2026-09-08T10:00:00.000',
      },
      'totals': <String, Object?>{
        'charges_total': '1065.00',
        'payments_total': '0.00',
        'outstanding_total': '0.00',
      },
      'currency': 'SAR',
      'payment': <String, Object?>{'status': 'settled', 'amount': '1065.00'},
      'invoice': <String, Object?>{
        'id': 21,
        'invoice_number': 'INV-4821-09',
        'status': 'issued',
        'issued_at': '2026-09-08T10:00:00.000',
      },
    }).toEntity();

    expect(result.checkout.status, CheckoutStatus.completed);
    expect(result.checkout.outstandingTotal.amount, 0);
    expect(result.settlementStatus, PaymentStatus.settled);
    expect(result.invoice!.invoiceNumber, 'INV-4821-09');
    expect(result.invoice!.status, InvoiceStatus.issued);
  });

  test('InvoiceModel maps an InvoiceResource payload with items', () {
    final invoice = InvoiceModel(<String, Object?>{
      'id': 21,
      'reservation_id': 7,
      'invoice_number': 'INV-4821-09',
      'status': 'issued',
      'currency': 'SAR',
      'subtotal': '1065.00',
      'payments_total': '1065.00',
      'outstanding_total': '0.00',
      'issued_at': '2026-09-08T10:00:00.000',
      'items': <Object?>[
        <String, Object?>{
          'source_type': 'folio_charge',
          'description': 'Accommodation',
          'quantity': 1,
          'unit_amount': '900.00',
          'total_amount': '900.00',
        },
      ],
    }).toEntity();

    expect(invoice.invoiceNumber, 'INV-4821-09');
    expect(invoice.subtotal.amount, 1065);
    expect(invoice.isSettled, isTrue);
    expect(invoice.items, hasLength(1));
    expect(invoice.items.first.totalAmount.amount, 900);
  });

  test('an unknown checkout status maps to inProgress defensively', () {
    final result = CheckoutResultModel(<String, Object?>{
      'reservation': <String, Object?>{'id': 1},
      'checkout': <String, Object?>{'status': 'weird'},
      'totals': <String, Object?>{},
      'currency': 'SAR',
    }).toEntity();
    expect(result.checkout.status, CheckoutStatus.inProgress);
  });
}
