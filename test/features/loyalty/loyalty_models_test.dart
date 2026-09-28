import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/loyalty/data/models/loyalty_models.dart';
import 'package:hotel_guest_app/features/loyalty/domain/entities/loyalty_transaction_type.dart';

void main() {
  group('LoyaltyAccountModel', () {
    test('maps the safe resource fields, tolerates missing ones', () {
      final account = LoyaltyAccountModel(<String, Object?>{
        'id': 7,
        'guest_id': 42,
        'points_balance': 1240,
        'is_active': true,
      }).toEntity();
      expect(account.id, '7');
      expect(account.guestId, '42');
      expect(account.pointsBalance, 1240);
      expect(account.isActive, isTrue);

      final empty = LoyaltyAccountModel(<String, Object?>{}).toEntity();
      expect(empty.id, isNull);
      expect(empty.pointsBalance, 0);
      expect(empty.isActive, isFalse);
    });
  });

  group('LoyaltyTransactionModel', () {
    test('reads the signed delta, source and metadata figures', () {
      final tx = LoyaltyTransactionModel(<String, Object?>{
        'id': 99,
        'type': 'redeem',
        'points': -290,
        'description': 'Points redeemed against a booking',
        'source_type': 'reservation',
        'source_id': 'r1',
        'created_at': '2026-09-01T09:00:00Z',
        'metadata': <String, Object?>{
          'notional_value': '14.50',
          'earn_base_amount': null,
        },
      }).toEntity();
      expect(tx.type, LoyaltyTransactionType.redeem);
      expect(tx.points, -290);
      expect(tx.isDebit, isTrue);
      expect(tx.sourceId, 'r1');
      expect(tx.notionalValue, '14.50');
      expect(tx.earnBaseAmount, isNull);
      expect(tx.createdAt, isNotNull);
    });

    test('an unknown type maps to adjust; a null type falls back too', () {
      expect(
        LoyaltyTransactionModel(<String, Object?>{'id': 1, 'type': 'bonus'})
            .toEntity()
            .type,
        LoyaltyTransactionType.adjust,
      );
      expect(
        LoyaltyTransactionModel(<String, Object?>{'id': 1}).toEntity().type,
        LoyaltyTransactionType.adjust,
      );
    });
  });

  group('RedeemLoyaltyPayload', () {
    test('serialises exactly { points } — nothing invented', () {
      expect(const RedeemLoyaltyPayload(150).toJson(),
          <String, Object?>{'points': 150});
    });
  });
}
