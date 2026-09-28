import '../../../../core/localization/content_language_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/reservation.dart';
import 'reservation_providers.dart';

/// A reservation by id, for the confirmation / details screen.
///
/// Always read from `ReservationRepository.getById` — never from the
/// just-created snapshot in `createReservationControllerProvider`: that
/// snapshot is frozen at PENDING, so after a mutation (payment hold, identity,
/// check-in) an `invalidate` would otherwise hand back the stale status and
/// gate the next step (e.g. identity verification showing "not ready" right
/// after a successful deposit hold). `autoDispose` so leaving the screen
/// drops the fetch.
final reservationDetailProvider =
    FutureProvider.autoDispose.family<Reservation, String>((Ref ref, String id) async {
  ref.watch(contentLanguageProvider); // refetch after a language switch
  return ref.watch(reservationRepositoryProvider).getById(id);
});
