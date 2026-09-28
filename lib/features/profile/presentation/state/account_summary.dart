import 'package:flutter/foundation.dart';

import '../../../authentication/domain/entities/guest_profile.dart';
import '../../../discovery/domain/entities/localized_text.dart';
import '../../../discovery/domain/entities/money.dart';
import '../../../loyalty/domain/entities/loyalty_account.dart';

/// Everything the Account screen (`PROFILE_Home.png`) shows, composed from
/// data the app already has — no new backend concept, no invented number.
///
/// [nightlyRate] / [loyalty] are read from one **anchor reservation** (the
/// guest's most recent reservation that carries a nightly rate) — loyalty is
/// a reservation-scoped read server-side (`/guest/reservations/{id}/loyalty`,
/// mirrors `LoyaltyContext.forReservation`) and the "per night" figure on the
/// same card is the same reservation's `room_type.base_price`, both real,
/// backend-authoritative values.
@immutable
class AccountSummary {
  const AccountSummary({
    required this.profile,
    required this.loyalty,
    required this.nightlyRate,
    required this.trustedGuest,
    required this.previousStaysCount,
    required this.preferredRoomName,
    this.activeStayReservationId,
    this.contactReservationId,
    this.loyaltyReservationId,
  });

  final GuestProfile? profile;
  final LoyaltyAccount loyalty;

  /// The anchor reservation's nightly rate, when one is known.
  final Money? nightlyRate;

  /// True once the guest has completed identity verification for at least
  /// one reservation (`verified` or any later status) — derived from
  /// reservation history already on hand, no extra call.
  final bool trustedGuest;

  /// Count of `checked_out` / `invoiced` reservations.
  final int previousStaysCount;

  /// The most-booked room type name across the guest's reservation history,
  /// when there is at least one reservation.
  final LocalizedText? preferredRoomName;

  /// The reservation the guest is staying on right now (checked in / in
  /// stay / checking out) — "الإبلاغ عن مشكلة" needs one.
  final String? activeStayReservationId;

  /// The stay whose hotel "تواصل مع الاستقبال" reaches: the active stay,
  /// else the next upcoming booking.
  final String? contactReservationId;

  /// The reservation the loyalty card opens (`LOYALTY_Overview` is
  /// reservation-scoped on the backend so hotel scope resolves server-side).
  final String? loyaltyReservationId;
}
