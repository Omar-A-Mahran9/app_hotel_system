import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/time/clock.dart';
import '../../data/datasources/api_service_review_data_source.dart';
import '../../data/datasources/dummy_service_review_data_source.dart';
import '../../data/datasources/service_review_data_source.dart';
import '../../data/repositories/service_review_repository_impl.dart';
import '../../domain/entities/service_order.dart';
import '../../domain/entities/service_review.dart';
import '../../domain/entities/service_review_draft.dart';
import '../../domain/repositories/service_review_repository.dart';
import 'stay_services_providers.dart';

/// One dummy instance holds any review submitted this session so a later
/// fetch is consistent. Kept alive — mirrors `_dummyReviewProvider`.
final _dummyServiceReviewProvider = Provider<DummyServiceReviewDataSource>(
  (Ref ref) => DummyServiceReviewDataSource(clock: ref.watch(clockProvider)),
);

/// Selects the service-reviews data source by configuration.
final serviceReviewDataSourceProvider = Provider<ServiceReviewDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? ref.watch(_dummyServiceReviewProvider)
      : ApiServiceReviewDataSource(ref.watch(apiClientProvider));
});

final serviceReviewRepositoryProvider = Provider<ServiceReviewRepository>(
  (Ref ref) => ServiceReviewRepositoryImpl(ref.watch(serviceReviewDataSourceProvider)),
);

/// The service-review context seeded from the authoritative service order.
final serviceReviewContextProvider = FutureProvider.autoDispose
    .family<ServiceReviewContext, ServiceOrderKey>((Ref ref, ServiceOrderKey key) async {
  final ServiceOrder order = await ref.watch(serviceOrderProvider(key).future);
  return ServiceReviewContext.forOrder(order);
});

/// The guest's existing review for a service order (or `null`).
final serviceOrderReviewProvider = FutureProvider.autoDispose
    .family<ServiceReview?, ServiceOrderKey>((Ref ref, ServiceOrderKey key) async {
  final ServiceReviewContext ctx =
      await ref.watch(serviceReviewContextProvider(key).future);
  return ref.watch(serviceReviewRepositoryProvider).reviewFor(ctx);
});
