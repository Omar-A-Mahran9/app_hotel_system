import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/clock.dart';
import '../../domain/entities/guest_party.dart';
import '../../domain/entities/room_selection.dart';
import '../../domain/entities/stay_range.dart';
import 'guest_party_controller.dart';
import 'stay_dates_controller.dart';

/// Holds the room the guest has chosen (`null` when nothing is selected).
///
/// The selection is only valid for the stay and party it was made against. This
/// controller watches [stayDatesControllerProvider] and
/// [guestPartyControllerProvider] and drops the selection the moment the guest
/// changes dates or guests, so a stale room can never appear valid for a
/// different stay. A hotel change is handled by the caller calling [clear] (the
/// hotel-detail screen already resets the flow).
class RoomSelectionController extends Notifier<RoomSelection?> {
  @override
  RoomSelection? build() {
    ref.listen<StayDatesDraft>(
      stayDatesControllerProvider,
      (_, _) => _revalidate(),
    );
    ref.listen<GuestParty>(
      guestPartyControllerProvider,
      (_, _) => _revalidate(),
    );
    return null;
  }

  void select(RoomSelection selection) => state = selection;

  void clear() => state = null;

  /// Reconciles the selection with the current dates + party.
  ///
  /// * A **date** change (or cleared/invalid dates) drops the selection — a room
  ///   priced for one stay can't carry over to another.
  /// * A **party** change keeps the selection and updates its party in place as
  ///   long as the new party still fits the room type (occupancy). This lets the
  ///   booking-summary steppers re-price without re-picking a room. A party that
  ///   no longer fits drops the selection.
  void _revalidate() {
    final RoomSelection? selection = state;
    if (selection == null) return;

    final DateTime today = _today();
    final StayRange? currentStay =
        ref.read(stayDatesControllerProvider).rangeAgainst(today);
    if (currentStay == null || currentStay != selection.stay) {
      state = null;
      return;
    }

    final GuestParty currentParty = ref.read(guestPartyControllerProvider);
    if (currentParty == selection.party) return;
    state = selection.fits(currentParty)
        ? selection.copyWith(party: currentParty)
        : null;
  }

  DateTime _today() {
    final DateTime now = ref.read(clockProvider)();
    return DateTime(now.year, now.month, now.day);
  }
}

final roomSelectionControllerProvider =
    NotifierProvider<RoomSelectionController, RoomSelection?>(
  RoomSelectionController.new,
);
