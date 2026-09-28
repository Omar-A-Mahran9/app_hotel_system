import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/time/clock.dart';
import '../../data/datasources/api_digital_access_data_source.dart';
import '../../data/datasources/digital_access_data_source.dart';
import '../../data/datasources/dummy_digital_access_data_source.dart';
import '../../data/repositories/digital_access_repository_impl.dart';
import '../../domain/entities/access_grant.dart';
import '../../domain/repositories/digital_access_repository.dart';

/// Selects the digital-access data source by configuration — the UI never sees
/// this choice, mirroring `paymentDataSourceProvider`. Kept alive for the whole
/// session so a grant issued here can be re-read by the access / reservation
/// screens.
final digitalAccessDataSourceProvider =
    Provider<DigitalAccessDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? DummyDigitalAccessDataSource(clock: ref.watch(clockProvider))
      : ApiDigitalAccessDataSource(ref.watch(apiClientProvider));
});

final digitalAccessRepositoryProvider = Provider<DigitalAccessRepository>(
  (Ref ref) =>
      DigitalAccessRepositoryImpl(ref.watch(digitalAccessDataSourceProvider)),
);

/// The current access grant for a reservation, for the check-in / access
/// screens. `autoDispose` so leaving the flow drops the fetch.
final accessGrantProvider = FutureProvider.autoDispose
    .family<AccessGrant, String>((Ref ref, String reservationId) {
  return ref.watch(digitalAccessRepositoryProvider).currentGrant(reservationId);
});
