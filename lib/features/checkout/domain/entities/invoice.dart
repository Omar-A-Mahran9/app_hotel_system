import 'package:flutter/foundation.dart';

import '../../../discovery/domain/entities/money.dart';
import 'checkout_status.dart';

/// A frozen invoice line, mirroring `InvoiceItemResource` (`source_type`,
/// `description`, `quantity`, `unit_amount`, `total_amount`). No tax / discount
/// / fee fields — none are approved.
@immutable
class InvoiceItem {
  const InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitAmount,
    required this.totalAmount,
    this.sourceType,
  });

  final String? sourceType;
  final String description;
  final int quantity;
  final Money unitAmount;
  final Money totalAmount;

  @override
  bool operator ==(Object other) =>
      other is InvoiceItem &&
      other.sourceType == sourceType &&
      other.description == description &&
      other.quantity == quantity &&
      other.unitAmount == unitAmount &&
      other.totalAmount == totalAmount;

  @override
  int get hashCode =>
      Object.hash(sourceType, description, quantity, unitAmount, totalAmount);
}

/// The final invoice for a reservation, mirroring the safe fields of
/// `InvoiceResource` (`invoice_number`, `status`, `currency`, `subtotal`,
/// `payments_total`, `outstanding_total`, `issued_at`, `items`).
///
/// ACCOUNTING: every money value is **backend-supplied**. The app never
/// computes a subtotal, a payments total, or an outstanding amount, and never
/// invents a tax/fee/discount line.
@immutable
class Invoice {
  const Invoice({
    required this.id,
    required this.reservationId,
    required this.invoiceNumber,
    required this.status,
    required this.currency,
    required this.subtotal,
    required this.paymentsTotal,
    required this.outstandingTotal,
    required this.items,
    this.issuedAt,
  });

  final String id;
  final String reservationId;
  final String invoiceNumber;
  final InvoiceStatus status;
  final String currency;
  final Money subtotal;
  final Money paymentsTotal;
  final Money outstandingTotal;
  final DateTime? issuedAt;
  final List<InvoiceItem> items;

  bool get isIssued => status.isIssued;
  bool get isSettled => outstandingTotal.amount <= 0;

  @override
  bool operator ==(Object other) =>
      other is Invoice &&
      other.id == id &&
      other.reservationId == reservationId &&
      other.invoiceNumber == invoiceNumber &&
      other.status == status &&
      other.currency == currency &&
      other.subtotal == subtotal &&
      other.paymentsTotal == paymentsTotal &&
      other.outstandingTotal == outstandingTotal &&
      other.issuedAt == issuedAt &&
      listEquals(other.items, items);

  @override
  int get hashCode => Object.hashAll(<Object?>[
        id,
        reservationId,
        invoiceNumber,
        status,
        currency,
        subtotal,
        paymentsTotal,
        outstandingTotal,
        issuedAt,
        Object.hashAll(items),
      ]);

  @override
  String toString() => 'Invoice($invoiceNumber, ${status.wireValue})';
}
