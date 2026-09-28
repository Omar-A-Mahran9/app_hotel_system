import '../../../core/localization/l10n.dart';
import '../domain/entities/service_order_status.dart';

/// Localized labels for the stay-services feature's enum. One home for the
/// enum → string mapping, mirroring `ReservationL10n`.
extension StayServicesL10n on AppLocalizations {
  String serviceOrderStatusLabel(ServiceOrderStatus status) => switch (status) {
        ServiceOrderStatus.requested => serviceStatusRequested,
        ServiceOrderStatus.confirmed => serviceStatusConfirmed,
        ServiceOrderStatus.fulfilled => serviceStatusFulfilled,
        ServiceOrderStatus.cancelled => serviceStatusCancelled,
      };
}
