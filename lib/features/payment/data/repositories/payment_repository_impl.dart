import '../../../../core/errors/error_mapper.dart';
import '../../../discovery/domain/entities/money.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/entities/payment_result.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_data_source.dart';

/// Coordinates the payment data source and maps DTO models to domain entities.
/// Which [PaymentDataSource] it holds (dummy vs API) is a DI decision, not made
/// here. Every data-layer error is mapped to a `Failure` via [ErrorMapper] so
/// the presentation layer only handles the user-safe type.
class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._dataSource);

  final PaymentDataSource _dataSource;

  @override
  Future<Payment> currentForReservation(String reservationId) =>
      _guard(() async {
        final model = await _dataSource.fetchForReservation(reservationId);
        return model?.toEntity() ??
            Payment.none(
              reservationId: reservationId,
              hotelId: '',
              amount: const Money(amount: 0),
            );
      });

  @override
  Future<PaymentResult> requestHold(PaymentHoldRequest request) => _guard(
        () async => PaymentResult.of(
          (await _dataSource.requestHold(request)).toEntity(),
        ),
      );

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }
}
