import 'dart:async';

import 'package:hotel_guest_app/features/discovery/presentation/widgets/hotel_location_map.dart';

/// Global setup for every test file (picked up by `flutter test`).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Map tiles can't load in widget tests, and the tile loader's real network /
  // on-disk cache I/O can hold a test process open for minutes.
  HotelLocationMap.tilesEnabled = false;
  await testMain();
}
