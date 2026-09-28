import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/time/clock.dart';
import '../../data/datasources/api_reservation_data_source.dart';
import '../../data/datasources/dummy_reservation_data_source.dart';
import '../../data/datasources/reservation_data_source.dart';
import '../../data/repositories/reservation_repository_impl.dart';
import '../../domain/repositories/reservation_repository.dart';

/// Selects the reservation data source by configuration — the UI never sees this
/// choice, mirroring `discoveryDataSourceProvider` / `authDataSourceProvider`.
///
/// The dummy source is kept alive for the whole app session so a reservation
/// created here can be re-fetched by id later (bookings, details).
final reservationDataSourceProvider = Provider<ReservationDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? DummyReservationDataSource(clock: ref.watch(clockProvider))
      : ApiReservationDataSource(ref.watch(apiClientProvider));
});

final reservationRepositoryProvider = Provider<ReservationRepository>(
  (Ref ref) =>
      ReservationRepositoryImpl(ref.watch(reservationDataSourceProvider)),
);
