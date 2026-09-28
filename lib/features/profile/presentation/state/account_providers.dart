import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/domain/entities/guest_profile.dart';
import '../../../authentication/presentation/state/auth_controller.dart';
import '../../../bookings/presentation/state/bookings_providers.dart';
import '../../../discovery/domain/entities/localized_text.dart';
import '../../../loyalty/domain/entities/loyalty_account.dart';
import '../../../loyalty/domain/entities/loyalty_operations.dart';
import '../../../loyalty/presentation/state/loyalty_providers.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/domain/entities/reservation_status.dart';
import 'account_summary.dart';

/// Reservation statuses that imply identity verification is already done
/// (Phase 0 §8: `VERIFIED` requires deposit held + identity verified, and
/// every later status is reached only by progressing past it). An explicit
/// positive list, never `!= pending && != cancelled` — mirrors
/// `Reservation.BLOCKING_STATUSES`'s own convention on the backend.
const Set<ReservationStatus> _identityVerifiedStatuses = <ReservationStatus>{
  ReservationStatus.verified,
  ReservationStatus.checkedIn,
  ReservationStatus.inStay,
  ReservationStatus.checkoutInProgress,
  ReservationStatus.checkoutBlocked,
  ReservationStatus.checkedOut,
  ReservationStatus.invoiced,
};

const Set<ReservationStatus> _activeStayStatuses = <ReservationStatus>{
  ReservationStatus.checkedIn,
  ReservationStatus.inStay,
  ReservationStatus.checkoutInProgress,
};

const Set<ReservationStatus> _upcomingStatuses = <ReservationStatus>{
  ReservationStatus.pending,
  ReservationStatus.depositHeld,
  ReservationStatus.verified,
};

const Set<ReservationStatus> _completedStatuses = <ReservationStatus>{
  ReservationStatus.checkedOut,
  ReservationStatus.invoiced,
};

final accountSummaryProvider = FutureProvider.autoDispose<AccountSummary>((Ref ref) async {
  final GuestProfile? profile = ref.watch(authControllerProvider).map(
        unknown: () => null,
        unauthenticated: () => null,
        awaitingProfile: (session) => session.profile,
        authenticated: (session) => session.profile,
        sessionExpired: () => null,
      );

  final List<Reservation> reservations =
      await ref.watch(bookingsListProvider.future);

  if (reservations.isEmpty) {
    return AccountSummary(
      profile: profile,
      loyalty: LoyaltyAccount.unknown,
      nightlyRate: null,
      trustedGuest: false,
      previousStaysCount: 0,
      preferredRoomName: null,
    );
  }

  final List<Reservation> byRecency = List<Reservation>.of(reservations)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final Reservation anchor = byRecency.firstWhere(
    (Reservation r) => r.nightlyRate != null,
    orElse: () => byRecency.first,
  );

  final LoyaltyAccount loyalty = await ref
      .watch(loyaltyRepositoryProvider)
      .account(LoyaltyContext.forReservation(anchor));

  final bool trustedGuest = reservations
      .any((Reservation r) => _identityVerifiedStatuses.contains(r.status));
  final int previousStaysCount = reservations
      .where((Reservation r) => _completedStatuses.contains(r.status))
      .length;

  final Map<String, int> counts = <String, int>{};
  final Map<String, LocalizedText> byKey = <String, LocalizedText>{};
  for (final Reservation r in reservations) {
    final String key = r.roomName.ar;
    if (key.isEmpty) continue;
    counts[key] = (counts[key] ?? 0) + 1;
    byKey[key] = r.roomName;
  }
  LocalizedText? preferredRoomName;
  if (counts.isNotEmpty) {
    final String topKey = counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    preferredRoomName = byKey[topKey];
  }

  final Reservation? activeStay = reservations
      .where((Reservation r) => _activeStayStatuses.contains(r.status))
      .firstOrNull;
  final List<Reservation> upcoming = reservations
      .where((Reservation r) => _upcomingStatuses.contains(r.status))
      .toList()
    ..sort((a, b) => a.stay.checkIn.compareTo(b.stay.checkIn));

  return AccountSummary(
    profile: profile,
    loyalty: loyalty,
    nightlyRate: anchor.nightlyRate,
    trustedGuest: trustedGuest,
    previousStaysCount: previousStaysCount,
    preferredRoomName: preferredRoomName,
    activeStayReservationId: activeStay?.id,
    contactReservationId: activeStay?.id ?? upcoming.firstOrNull?.id,
    loyaltyReservationId: anchor.id,
  );
});
