import 'package:flutter/foundation.dart';

import '../../domain/entities/money.dart';
import '../../domain/entities/room_selection.dart';

/// The price rows shown on the booking summary. Pure presentation arithmetic
/// over values the app already holds — the service fee is the hotel's own
/// (`HotelServiceFee`), the same figure the server snapshots on booking.
@immutable
class BookingPriceBreakdown {
  const BookingPriceBreakdown({
    required this.roomSubtotal,
    required this.serviceFee,
    required this.total,
    this.loyaltyDiscount,
  });

  factory BookingPriceBreakdown.of(
    RoomSelection selection, {
    Money? serviceFee,
    num loyaltyDiscount = 0,
  }) {
    final Money subtotal = selection.stayTotal;
    final num total =
        subtotal.amount + (serviceFee?.amount ?? 0) - loyaltyDiscount;
    return BookingPriceBreakdown(
      roomSubtotal: subtotal,
      serviceFee: serviceFee,
      loyaltyDiscount: loyaltyDiscount > 0
          ? Money(amount: loyaltyDiscount, currency: subtotal.currency)
          : null,
      total: Money(amount: total, currency: subtotal.currency),
    );
  }

  final Money roomSubtotal;
  final Money? serviceFee;

  /// The estimated points discount (server decides the final credit).
  final Money? loyaltyDiscount;
  final Money total;
}
