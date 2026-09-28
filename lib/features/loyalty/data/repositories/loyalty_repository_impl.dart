import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/loyalty_account.dart';
import '../../domain/entities/loyalty_operations.dart';
import '../../domain/entities/loyalty_program.dart';
import '../../domain/entities/loyalty_transaction.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../datasources/loyalty_data_source.dart';

/// Coordinates the loyalty data source. Dummy vs API is a DI decision. Every
/// data-layer *infrastructure* error is mapped to a `Failure` via
/// [ErrorMapper]; **business** outcomes ride on the result objects and are
/// passed straight through (never turned into a false success, never a local
/// balance mutation).
class LoyaltyRepositoryImpl implements LoyaltyRepository {
  LoyaltyRepositoryImpl(this._dataSource);

  final LoyaltyDataSource _dataSource;

  @override
  Future<LoyaltyAccount> account(LoyaltyContext context) =>
      _guard(() => _dataSource.fetchAccount(context));

  @override
  Future<LoyaltyProgram> program(String hotelId) =>
      _guard(() => _dataSource.fetchProgram(hotelId));

  @override
  Future<List<LoyaltyTransaction>> transactions(LoyaltyContext context) =>
      _guard(() => _dataSource.fetchTransactions(context));

  @override
  Future<RedeemPointsResult> redeem(
    RedeemPointsRequest request,
    LoyaltyContext context,
  ) =>
      _guard(() => _dataSource.redeem(request, context));

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }
}
