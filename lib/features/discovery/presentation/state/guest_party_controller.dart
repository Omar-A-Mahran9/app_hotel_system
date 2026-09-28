import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/guest_party.dart';

/// The guest count for the current stay (`16 · Stay dates & available rooms`,
/// the "عدد الضيوف" sheet). Held across the dates → rooms screens.
class GuestPartyController extends Notifier<GuestParty> {
  @override
  GuestParty build() => GuestParty.initial;

  void setAdults(int value) => state = state.copyWith(adults: value);

  void setChildren(int value) => state = state.copyWith(children: value);

  void incrementAdults() => setAdults(state.adults + 1);

  void decrementAdults() => setAdults(state.adults - 1);

  void incrementChildren() => setChildren(state.children + 1);

  void decrementChildren() => setChildren(state.children - 1);

  void reset() => state = GuestParty.initial;
}

final guestPartyControllerProvider =
    NotifierProvider<GuestPartyController, GuestParty>(GuestPartyController.new);
