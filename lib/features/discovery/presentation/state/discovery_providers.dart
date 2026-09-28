import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../data/datasources/api_discovery_data_source.dart';
import '../../data/datasources/discovery_data_source.dart';
import '../../data/datasources/dummy_discovery_data_source.dart';
import '../../data/repositories/discovery_repository_impl.dart';
import '../../domain/repositories/discovery_repository.dart';

/// Selects the discovery data source by configuration — the UI never sees this
/// choice (README — "Development Strategy"), mirroring `authDataSourceProvider`.
final discoveryDataSourceProvider = Provider<DiscoveryDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? DummyDiscoveryDataSource(singleHotelGroup: config.singleHotelGroup)
      : ApiDiscoveryDataSource(ref.watch(apiClientProvider));
});

final discoveryRepositoryProvider = Provider<DiscoveryRepository>(
  (Ref ref) => DiscoveryRepositoryImpl(ref.watch(discoveryDataSourceProvider)),
);
