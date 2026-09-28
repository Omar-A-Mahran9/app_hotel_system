import '../../domain/entities/checkout.dart';
import '../../domain/entities/folio.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/checkout_repository.dart';

/// The checkout data contract. Dummy + API implementations selected by DI.
abstract interface class CheckoutDataSource {
  Future<Folio> fetchFolio(FolioContext context);

  Future<CheckoutResult> performCheckout(
    CheckoutRequest request,
    FolioContext context,
  );
}

/// The invoice data contract. Kept separate so it can be fulfilled by the same
/// dummy instance (shared checkout state) or a distinct API source.
abstract interface class InvoiceDataSource {
  Future<Invoice> fetchInvoice(String reservationId);
}
