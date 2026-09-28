import '../../../core/localization/l10n.dart';
import '../domain/entities/checkout_status.dart';
import '../domain/entities/folio.dart';

/// Localized labels for the checkout feature's enums and for known folio /
/// invoice line source types (the backend sends a plain English `description`;
/// the app localises the ones it recognises and falls back to the description
/// for anything else).
extension CheckoutL10n on AppLocalizations {
  String checkoutStatusLabel(CheckoutStatus status) => switch (status) {
        CheckoutStatus.inProgress => checkoutStatusInProgress,
        CheckoutStatus.awaitingSettlement => checkoutStatusAwaitingSettlement,
        CheckoutStatus.settlementFailed => checkoutStatusSettlementFailed,
        CheckoutStatus.completed => checkoutStatusCompleted,
      };

  String folioChargeLabel(FolioCharge charge) => switch (charge.sourceType) {
        'accommodation' => folioAccommodationLine,
        'service_order' =>
          charge.description.isEmpty ? folioServiceLine : charge.description,
        _ => charge.description.isEmpty ? folioServiceLine : charge.description,
      };
}
