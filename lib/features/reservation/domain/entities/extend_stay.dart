import 'package:flutter/foundation.dart';

import '../../../discovery/domain/entities/money.dart';

/// Everything the mobile app can supply to request a stay extension.
///
/// The approved backend `POST
/// /api/v1/guest/reservations/{reservation}/extend`
/// (`ExtendGuestReservationRequest`) takes only `new_check_out` — eligibility
/// (`checked_in`/`in_stay`), availability for the added nights and the
/// resulting price are all derived server-side by
/// `ReservationExtensionService`. No amount is ever supplied by the app
/// (mobile/docs/architecture.md §6 — the app invents no pricing).
@immutable
class ExtendStayRequest {
  const ExtendStayRequest({
    required this.reservationId,
    required this.newCheckOut,
  });

  final String reservationId;
  final DateTime newCheckOut;

  /// A stable idempotency key for this exact request — used as the
  /// `Idempotency-Key` header and to dedupe repeated submits. No time
  /// component, no randomness.
  String get idempotencyKey =>
      'extend:$reservationId:${newCheckOut.toIso8601String().split('T').first}';

  @override
  bool operator ==(Object other) =>
      other is ExtendStayRequest &&
      other.reservationId == reservationId &&
      other.newCheckOut == newCheckOut;

  @override
  int get hashCode => Object.hash(reservationId, newCheckOut);
}

/// The authoritative outcome of a stay-extension request, mirroring the
/// backend's `{ reservation, extension, folio }` composite response. The app
/// never computes [nightsAdded] / [amount] itself — these are exactly what
/// the backend returned.
@immutable
class ExtendStayResult {
  const ExtendStayResult({
    required this.reservationId,
    required this.newCheckOut,
    required this.nightsAdded,
    required this.amount,
    required this.outstandingTotal,
  });

  final String reservationId;
  final DateTime newCheckOut;
  final int nightsAdded;

  /// The incremental amount charged for this extension.
  final Money amount;

  /// The reservation's folio outstanding total *after* this extension —
  /// settled at checkout, same as every other folio charge.
  final Money outstandingTotal;

  @override
  bool operator ==(Object other) =>
      other is ExtendStayResult &&
      other.reservationId == reservationId &&
      other.newCheckOut == newCheckOut &&
      other.nightsAdded == nightsAdded &&
      other.amount == amount &&
      other.outstandingTotal == outstandingTotal;

  @override
  int get hashCode => Object.hash(
        reservationId,
        newCheckOut,
        nightsAdded,
        amount,
        outstandingTotal,
      );
}
