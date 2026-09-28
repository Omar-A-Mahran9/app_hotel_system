import '../entities/checkout.dart';
import '../entities/folio.dart';
import '../entities/invoice.dart';

/// The context the guest app can seed a folio read with while there is no
/// guest-facing folio endpoint. The real `GET .../folio` needs none of this
/// (the server derives every figure); the dummy source uses it to build a folio
/// consistent with the reservation the guest already sees.
class FolioContext {
  const FolioContext({
    required this.reservationId,
    required this.accommodationAmount,
    required this.currency,
  });

  final String reservationId;
  final num accommodationAmount;
  final String currency;
}

/// The checkout contract the presentation layer depends on. Dummy vs API is a
/// DI decision, exactly as in `PaymentRepository`.
///
/// ACCOUNTING: every money value returned is backend-authoritative. The app
/// never computes a settlement amount, a subtotal, or an outstanding balance.
abstract interface class CheckoutRepository {
  /// The reservation folio (charges + backend totals).
  Future<Folio> folioFor(FolioContext context);

  /// Performs checkout. The backend settles any outstanding amount and issues
  /// the invoice; nothing here transitions the reservation or computes money.
  Future<CheckoutResult> checkout(CheckoutRequest request, FolioContext context);
}

/// The invoice contract. Separate from checkout because the invoice is read
/// long after checkout (re-opening the e-invoice) with full line-item detail.
abstract interface class InvoiceRepository {
  /// The reservation's final invoice. Throws a `notFound` `Failure` when no
  /// invoice has been issued yet (mirrors the backend 404).
  Future<Invoice> invoiceFor(String reservationId);
}
