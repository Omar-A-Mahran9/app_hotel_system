import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/checkout.dart';
import '../../domain/entities/folio.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../datasources/checkout_data_source.dart';

/// Coordinates the checkout data source. Dummy vs API is a DI decision. Every
/// data-layer error is mapped to a `Failure` via [ErrorMapper]. No arithmetic
/// happens here — the datasource returns backend-authoritative totals.
class CheckoutRepositoryImpl implements CheckoutRepository {
  CheckoutRepositoryImpl(this._dataSource);

  final CheckoutDataSource _dataSource;

  @override
  Future<Folio> folioFor(FolioContext context) =>
      _guard(() => _dataSource.fetchFolio(context));

  @override
  Future<CheckoutResult> checkout(
    CheckoutRequest request,
    FolioContext context,
  ) =>
      _guard(() => _dataSource.performCheckout(request, context));

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }
}

/// Coordinates the invoice data source.
class InvoiceRepositoryImpl implements InvoiceRepository {
  InvoiceRepositoryImpl(this._dataSource);

  final InvoiceDataSource _dataSource;

  @override
  Future<Invoice> invoiceFor(String reservationId) async {
    try {
      return await _dataSource.fetchInvoice(reservationId);
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }
}
