import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/time/clock.dart';
import '../../../reservation/domain/entities/reservation.dart';
import '../../../reservation/presentation/state/reservation_detail_provider.dart';
import '../../data/datasources/api_payment_data_source.dart';
import '../../data/datasources/dummy_payment_data_source.dart';
import '../../data/datasources/payment_data_source.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../../discovery/domain/entities/money.dart';

/// Selects the payment data source by configuration — the UI never sees this
/// choice, mirroring `reservationDataSourceProvider`.
///
/// The dummy source is kept alive for the whole app session so a hold placed
/// here can be re-read by the result / reservation screens.
final paymentDataSourceProvider = Provider<PaymentDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? DummyPaymentDataSource(clock: ref.watch(clockProvider))
      : ApiPaymentDataSource(ref.watch(apiClientProvider));
});

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (Ref ref) => PaymentRepositoryImpl(ref.watch(paymentDataSourceProvider)),
);

/// The current payment for a reservation, for the review / result screens.
///
/// When no payment record exists yet the repository returns a synthetic
/// [Payment.none]; this provider fills its hotel id and amount from the
/// authoritative [Reservation] — the server-computed deposit
/// (`hotel.deposit_amount`), never the stay total — so the review screen
/// shows the right figure before the first hold. `autoDispose` so leaving the flow drops the fetch.
final currentPaymentProvider = FutureProvider.autoDispose
    .family<Payment, String>((Ref ref, String reservationId) async {
  final Payment payment =
      await ref.watch(paymentRepositoryProvider).currentForReservation(
            reservationId,
          );
  if (payment.exists) return payment;

  final Reservation reservation =
      await ref.watch(reservationDetailProvider(reservationId).future);
  return Payment.none(
    reservationId: reservationId,
    hotelId: reservation.hotelId,
    amount: reservation.depositAmount ??
        Money(amount: 0, currency: reservation.priceSnapshot.currency),
  );
});
