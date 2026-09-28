import 'package:dio/dio.dart';

import '../../../../core/data/data_source.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/checkout.dart';
import '../../domain/entities/folio.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../models/checkout_models.dart';
import 'checkout_data_source.dart';

/// API-backed checkout + invoice source.
///
/// Real, authenticated guest contract, all reusing the shared
/// staff-agnostic resources (no guest-specific shape needed — none of them
/// carry staff attribution):
/// `GET /guest/reservations/{reservation}/folio` → `FolioResource`,
/// `POST /guest/reservations/{reservation}/checkout` → `CheckoutResource`,
/// `GET /guest/reservations/{reservation}/invoice` → `InvoiceResource`.
///
/// The settlement amount is always computed server-side from the
/// authoritative folio — this never sends or derives one.
///
/// `GuestCheckoutController::store` returns a 422 (not a `CheckoutResource`)
/// when settlement is pending or has failed — `errors.checkout_status` /
/// `errors.payment_status` only, no totals. On that 422 this re-reads the
/// real folio (`GET .../folio`, a real endpoint) to assemble a genuine
/// `CheckoutResult` from two authoritative reads rather than inventing any
/// figure, so `CheckoutOutcome.settlementPending` / `settlementFailed` are
/// reachable the same way a caller reading `CheckoutResource` directly would
/// see them.
class ApiCheckoutDataSource
    implements CheckoutDataSource, InvoiceDataSource, RemoteDataSource {
  ApiCheckoutDataSource(this._client);

  final ApiClient _client;

  @override
  Future<Folio> fetchFolio(FolioContext context) async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/reservations/${context.reservationId}/folio',
    );
    final Map<String, Object?> data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
    return FolioModel(data).toEntity();
  }

  @override
  Future<CheckoutResult> performCheckout(
    CheckoutRequest request,
    FolioContext context,
  ) async {
    try {
      final Map<String, dynamic> json = await _client.postJson(
        '/guest/reservations/${request.reservationId}/checkout',
        headers: <String, String>{'Idempotency-Key': request.idempotencyKey},
      );
      final Map<String, Object?> data =
          (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
      return CheckoutResultModel(data).toEntity();
    } on DioException catch (e) {
      final Object? body = e.response?.data;
      final Object? errors = body is Map ? body['errors'] : null;
      final String? checkoutStatus =
          errors is Map ? errors['checkout_status'] as String? : null;
      if (e.response?.statusCode == 422 && checkoutStatus != null) {
        final String? paymentStatus = errors is Map ? errors['payment_status'] as String? : null;
        final Folio folio = await fetchFolio(context);
        return CheckoutResultModel(<String, Object?>{
          'reservation': <String, Object?>{'id': request.reservationId},
          'checkout': <String, Object?>{'status': checkoutStatus},
          'totals': <String, Object?>{
            'charges_total': folio.chargesTotal.amount,
            'payments_total': folio.paymentsTotal.amount,
            'outstanding_total': folio.outstandingTotal.amount,
          },
          'currency': folio.currency,
          'payment': paymentStatus == null
              ? null
              : <String, Object?>{'status': paymentStatus},
          'invoice': null,
        }).toEntity();
      }
      rethrow;
    }
  }

  @override
  Future<Invoice> fetchInvoice(String reservationId) async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/reservations/$reservationId/invoice',
    );
    final Map<String, Object?> data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
    return InvoiceModel(data).toEntity();
  }
}
