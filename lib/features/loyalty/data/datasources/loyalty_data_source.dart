import '../../domain/entities/loyalty_account.dart';
import '../../domain/entities/loyalty_operations.dart';
import '../../domain/entities/loyalty_program.dart';
import '../../domain/entities/loyalty_transaction.dart';

/// The loyalty data contract. Dummy + API implementations selected by DI
/// (`AppConfig.useDummyData`), exactly like `CheckoutDataSource`.
///
/// The methods return domain entities directly (the loyalty payloads are small
/// and the outcome classification for redeem is a domain concern the
/// dummy resolves deterministically and the API adapter will translate from
/// the backend's 422 reason codes).
abstract interface class LoyaltyDataSource {
  Future<LoyaltyAccount> fetchAccount(LoyaltyContext context);

  /// The hotel group's program + the guest's balance (booking summary).
  Future<LoyaltyProgram> fetchProgram(String hotelId);

  Future<List<LoyaltyTransaction>> fetchTransactions(LoyaltyContext context);

  Future<RedeemPointsResult> redeem(
    RedeemPointsRequest request,
    LoyaltyContext context,
  );
}
