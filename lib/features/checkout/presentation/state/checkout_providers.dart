import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/time/clock.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/state/reservation_detail_provider.dart';
import '../../data/datasources/api_checkout_data_source.dart';
import '../../data/datasources/checkout_data_source.dart';
import '../../data/datasources/dummy_checkout_data_source.dart';
import '../../data/repositories/checkout_repository_impl.dart';
import '../../domain/entities/folio.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/checkout_repository.dart';

/// One dummy instance backs both the checkout and the invoice data contracts so
/// a checkout completed here makes the invoice fetchable. Kept alive for the
/// session.
final _dummyCheckoutBundleProvider = Provider<DummyCheckoutDataSource>(
  (Ref ref) => DummyCheckoutDataSource(clock: ref.watch(clockProvider)),
);

final checkoutDataSourceProvider = Provider<CheckoutDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? ref.watch(_dummyCheckoutBundleProvider)
      : ApiCheckoutDataSource(ref.watch(apiClientProvider));
});

final invoiceDataSourceProvider = Provider<InvoiceDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? ref.watch(_dummyCheckoutBundleProvider)
      : ApiCheckoutDataSource(ref.watch(apiClientProvider));
});

final checkoutRepositoryProvider = Provider<CheckoutRepository>(
  (Ref ref) => CheckoutRepositoryImpl(ref.watch(checkoutDataSourceProvider)),
);

final invoiceRepositoryProvider = Provider<InvoiceRepository>(
  (Ref ref) => InvoiceRepositoryImpl(ref.watch(invoiceDataSourceProvider)),
);

/// The seed context the app can supply for a folio read (from the authoritative
/// reservation the guest already sees). The real API needs none of this.
final folioContextProvider = FutureProvider.autoDispose
    .family<FolioContext, String>((Ref ref, String reservationId) async {
  final Reservation r =
      await ref.watch(reservationDetailProvider(reservationId).future);
  return FolioContext(
    reservationId: reservationId,
    accommodationAmount: r.priceSnapshot.amount,
    currency: r.priceSnapshot.currency,
  );
});

/// The reservation folio.
final folioProvider = FutureProvider.autoDispose
    .family<Folio, String>((Ref ref, String reservationId) async {
  final FolioContext ctx =
      await ref.watch(folioContextProvider(reservationId).future);
  return ref.watch(checkoutRepositoryProvider).folioFor(ctx);
});

/// The reservation's final invoice (throws a `notFound` `Failure` before
/// checkout completes).
final invoiceProvider = FutureProvider.autoDispose
    .family<Invoice, String>((Ref ref, String reservationId) {
  return ref.watch(invoiceRepositoryProvider).invoiceFor(reservationId);
});
