import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/loyalty/data/models/loyalty_models.dart';
import 'package:hotel_guest_app/features/loyalty/domain/entities/loyalty_program.dart';

void main() {
  const LoyaltyProgram program = LoyaltyProgram(
    enabled: true,
    redeemValuePerPoint: 0.1,
    maxRedeemPoints: 500,
    pointsBalance: 1240,
    redeemablePoints: 500,
  );

  test('discount = points x rate, capped at the stay total', () {
    expect(program.discountFor(500, stayTotal: 900), 50);
    expect(program.discountFor(333, stayTotal: 900), 33.3);
    expect(program.discountFor(500, stayTotal: 20), 20);
    expect(program.discountFor(0, stayTotal: 900), 0);
  });

  test('points for a discount round up and never pass the redeemable cap', () {
    expect(program.pointsFor(25), 250);
    expect(program.pointsFor(25.05), 251);
    expect(program.pointsFor(999), 500);
    expect(program.pointsFor(0), 0);
  });

  test('the launch program (disabled) cannot redeem', () {
    expect(LoyaltyProgram.disabled.canRedeem, isFalse);
    expect(program.canRedeem, isTrue);
  });

  test('parses the guest program payload (decimal-string rates)', () {
    final LoyaltyProgram parsed = const LoyaltyProgramModel(<String, Object?>{
      'enabled': true,
      'earn_points_per_currency': '1.0000',
      'redeem_currency_per_point': '0.1000',
      'max_redeem_points': 500,
      'points_balance': 1240,
      'redeemable_points': 500,
    }).toEntity();
    expect(parsed, program);

    expect(
      const LoyaltyProgramModel(<String, Object?>{'enabled': false}).toEntity(),
      LoyaltyProgram.disabled,
    );
  });
}
