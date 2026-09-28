import '../../../core/localization/l10n.dart';
import '../domain/entities/loyalty_operations.dart';
import '../domain/entities/loyalty_transaction_type.dart';

/// Localized labels for the loyalty feature's enums. One home for the enum →
/// string mapping, mirroring `CheckoutL10n`.
extension LoyaltyL10n on AppLocalizations {
  String loyaltyTransactionTypeLabel(LoyaltyTransactionType type) =>
      switch (type) {
        LoyaltyTransactionType.earn => loyaltyTxEarnLabel,
        LoyaltyTransactionType.redeem => loyaltyTxRedeemLabel,
        LoyaltyTransactionType.reverse => loyaltyTxReverseLabel,
        LoyaltyTransactionType.adjust => loyaltyTxAdjustLabel,
        LoyaltyTransactionType.expire => loyaltyTxExpireLabel,
      };

  /// Result-banner title for a redeem outcome.
  String loyaltyRedeemOutcomeTitle(LoyaltyRedeemOutcome o) => switch (o) {
        LoyaltyRedeemOutcome.redeemed => loyaltyRedeemedTitle,
        LoyaltyRedeemOutcome.alreadyRedeemed => loyaltyAlreadyRedeemedTitle,
        LoyaltyRedeemOutcome.alreadyRedeemedDifferent => loyaltyAlreadyRedeemedTitle,
        LoyaltyRedeemOutcome.insufficientPoints => loyaltyInsufficientTitle,
        LoyaltyRedeemOutcome.notEligible => loyaltyRedeemNotEligibleTitle,
        LoyaltyRedeemOutcome.programInactive => loyaltyProgramOffTitle,
        LoyaltyRedeemOutcome.invalidAmount => loyaltyInsufficientTitle,
      };

  String loyaltyRedeemOutcomeBody(LoyaltyRedeemOutcome o) => switch (o) {
        LoyaltyRedeemOutcome.alreadyRedeemed => loyaltyAlreadyRedeemedBody,
        LoyaltyRedeemOutcome.alreadyRedeemedDifferent =>
          loyaltyAlreadyRedeemedDifferentBody,
        LoyaltyRedeemOutcome.insufficientPoints => loyaltyInsufficientBody,
        LoyaltyRedeemOutcome.notEligible => loyaltyRedeemNotEligibleBody,
        LoyaltyRedeemOutcome.programInactive => loyaltyProgramOffBody,
        LoyaltyRedeemOutcome.invalidAmount => loyaltyInvalidAmountBody,
        LoyaltyRedeemOutcome.redeemed => loyaltyProgramOffBody, // unused
      };
}
