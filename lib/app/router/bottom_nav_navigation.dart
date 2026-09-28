import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_bottom_nav.dart';
import 'app_routes.dart';

/// Maps an [AppNavTab] to its root route and navigates there.
///
/// All four tabs are real destinations from Mobile Phase 11 on
/// (`DiscoverPage`, `BookingsListPage`, `StayHomePage`, `AccountHomePage`);
/// each root page passes this to its own `AppBottomNav` so the tab bar
/// behaves identically everywhere.
void goToNavTab(BuildContext context, AppNavTab tab) {
  final String name = switch (tab) {
    AppNavTab.home => AppRoutes.discoverName,
    AppNavTab.bookings => AppRoutes.bookingsName,
    AppNavTab.services => AppRoutes.stayHomeName,
    AppNavTab.account => AppRoutes.accountName,
  };
  context.goNamed(name);
}
