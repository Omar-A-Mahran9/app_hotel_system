import '../../../core/localization/l10n.dart';
import '../domain/entities/review.dart';

/// Localized labels for the reviews feature's enum. One home for the enum →
/// string mapping, mirroring `CheckoutL10n`.
extension ReviewsL10n on AppLocalizations {
  String reviewStatusLabel(ReviewStatus status) => switch (status) {
        ReviewStatus.pending => reviewStatusPending,
        ReviewStatus.published => reviewStatusPublished,
        ReviewStatus.rejected => reviewStatusRejected,
      };
}
