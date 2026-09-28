import '../../../../core/localization/content_language_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/state/reservation_providers.dart';
import '../../domain/bookings_filter.dart';

/// The guest's own reservations, newest first — backs the Bookings tab and
/// the Account screen's derived stats (previous stays, trusted-guest,
/// preferences).
final bookingsListProvider = FutureProvider.autoDispose<List<Reservation>>(
  (Ref ref) {
  // Refetch in the new language after a language switch.
  ref.watch(contentLanguageProvider);
    return ref.watch(reservationRepositoryProvider).list();
  },
);

/// The selected pill on the Bookings tab. Local UI state — resets to
/// [BookingsFilter.current] whenever the page is rebuilt fresh.
final bookingsFilterProvider =
    StateProvider.autoDispose<BookingsFilter>((Ref ref) => BookingsFilter.current);
