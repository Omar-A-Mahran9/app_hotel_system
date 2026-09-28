// Data-transfer models for the loyalty feature.
//
// `LoyaltyAccountModel` mirrors `LoyaltyAccountResource`; `LoyaltyTransactionModel`
// mirrors `LoyaltyTransactionResource`. The earn endpoint has no request body;
// the redeem body is `{ points }`. No card / payment / provider data exists on
// any loyalty payload.

import '../../domain/entities/loyalty_account.dart';
import '../../domain/entities/loyalty_program.dart';
import '../../domain/entities/loyalty_transaction.dart';
import '../../domain/entities/loyalty_transaction_type.dart';

typedef Json = Map<String, Object?>;

DateTime? _dateOrNull(Object? raw) {
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  return null;
}

String? _metaString(Object? metadata, String key) {
  if (metadata is Map && metadata[key] != null) return '${metadata[key]}';
  return null;
}

class LoyaltyAccountModel {
  const LoyaltyAccountModel(this._json);
  final Json _json;

  LoyaltyAccount toEntity() => LoyaltyAccount(
        id: _json['id'] == null ? null : '${_json['id']}',
        guestId: _json['guest_id'] == null ? null : '${_json['guest_id']}',
        pointsBalance: (_json['points_balance'] as num?)?.toInt() ?? 0,
        isActive: _json['is_active'] as bool? ?? false,
      );
}

/// `GET /guest/hotels/{hotel}/loyalty` → [LoyaltyProgram]. Rates arrive as
/// decimal strings.
class LoyaltyProgramModel {
  const LoyaltyProgramModel(this._json);
  final Json _json;

  LoyaltyProgram toEntity() => LoyaltyProgram(
        enabled: _json['enabled'] as bool? ?? false,
        redeemValuePerPoint:
            num.tryParse('${_json['redeem_currency_per_point'] ?? ''}') ?? 0,
        maxRedeemPoints: (_json['max_redeem_points'] as num?)?.toInt() ?? 0,
        pointsBalance: (_json['points_balance'] as num?)?.toInt() ?? 0,
        redeemablePoints: (_json['redeemable_points'] as num?)?.toInt() ?? 0,
      );
}

class LoyaltyTransactionModel {
  const LoyaltyTransactionModel(this._json);
  final Json _json;

  LoyaltyTransaction toEntity() {
    final Object? metadata = _json['metadata'];
    return LoyaltyTransaction(
      id: '${_json['id']}',
      type: LoyaltyTransactionType.fromWire(
        (_json['type'] as String?) ?? LoyaltyTransactionType.adjust.wireValue,
      ),
      points: (_json['points'] as num?)?.toInt() ?? 0,
      description: _json['description'] as String?,
      sourceType: _json['source_type'] as String?,
      sourceId: _json['source_id'] == null ? null : '${_json['source_id']}',
      createdAt: _dateOrNull(_json['created_at']),
      earnBaseAmount: _metaString(metadata, 'earn_base_amount'),
      notionalValue: _metaString(metadata, 'notional_value'),
    );
  }
}

/// The redeem request body, as far as the documented contract goes.
class RedeemLoyaltyPayload {
  const RedeemLoyaltyPayload(this.points);

  final int points;

  Json toJson() => <String, Object?>{'points': points};
}
