import 'package:flutter/foundation.dart';

import '../../../discovery/domain/entities/money.dart';

/// One line on the reservation folio, mirroring the safe fields of
/// `FolioChargeResource` (`source_type`, `description`, `quantity`,
/// `unit_amount`, `total_amount`, `currency`, `status`, `charged_at`). No card
/// data / provider secret is ever present on a folio charge.
///
/// ACCOUNTING: [totalAmount] is the **authoritative** figure — the app never
/// recomputes it.
@immutable
class FolioCharge {
  const FolioCharge({
    required this.id,
    required this.sourceType,
    required this.description,
    required this.quantity,
    required this.unitAmount,
    required this.totalAmount,
    required this.status,
    this.chargedAt,
  });

  final String id;

  /// `accommodation` | `service_order` (backend `FolioCharge` source types).
  final String sourceType;
  final String description;
  final int quantity;
  final Money unitAmount;
  final Money totalAmount;

  /// `posted` | `cancelled` (backend `FolioCharge::STATUSES`).
  final String status;
  final DateTime? chargedAt;

  bool get isPosted => status == 'posted';
  bool get isAccommodation => sourceType == 'accommodation';

  @override
  bool operator ==(Object other) =>
      other is FolioCharge &&
      other.id == id &&
      other.sourceType == sourceType &&
      other.description == description &&
      other.quantity == quantity &&
      other.unitAmount == unitAmount &&
      other.totalAmount == totalAmount &&
      other.status == status &&
      other.chargedAt == chargedAt;

  @override
  int get hashCode => Object.hash(id, sourceType, description, quantity,
      unitAmount, totalAmount, status, chargedAt);
}

/// The reservation folio read model, mirroring `FolioResource` (`currency`,
/// `charges`, `totals { charges_total, payments_total, outstanding_total }`,
/// `payment_summary`).
///
/// ACCOUNTING: every total here is **backend-supplied**. The app displays them;
/// it never sums the charges itself, never derives the outstanding amount, and
/// never uses a payment's `amount` as a transactions total.
@immutable
class Folio {
  const Folio({
    required this.reservationId,
    required this.currency,
    required this.charges,
    required this.chargesTotal,
    required this.paymentsTotal,
    required this.outstandingTotal,
  });

  final String reservationId;
  final String currency;
  final List<FolioCharge> charges;

  /// Backend `totals.charges_total`.
  final Money chargesTotal;

  /// Backend `totals.payments_total`.
  final Money paymentsTotal;

  /// Backend `totals.outstanding_total` — what will be settled at checkout.
  final Money outstandingTotal;

  List<FolioCharge> get postedCharges =>
      charges.where((FolioCharge c) => c.isPosted).toList(growable: false);

  bool get hasOutstanding => outstandingTotal.amount > 0;

  @override
  bool operator ==(Object other) =>
      other is Folio &&
      other.reservationId == reservationId &&
      other.currency == currency &&
      listEquals(other.charges, charges) &&
      other.chargesTotal == chargesTotal &&
      other.paymentsTotal == paymentsTotal &&
      other.outstandingTotal == outstandingTotal;

  @override
  int get hashCode => Object.hash(reservationId, currency,
      Object.hashAll(charges), chargesTotal, paymentsTotal, outstandingTotal);
}
