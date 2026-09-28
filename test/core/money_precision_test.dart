import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/widgets/money_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';

void main() {
  test('Money.parseAmount keeps halalas and whole amounts as ints', () {
    expect(Money.parseAmount('93.20'), 93.2);
    expect(Money.parseAmount('945.00'), 945);
    expect(Money.parseAmount('945.00'), isA<int>());
    expect(Money.parseAmount(12.5), 12.5);
    expect(Money.parseAmount(7), 7);
    expect(Money.parseAmount('0.005'), 0.01);
    expect(Money.parseAmount(null), 0);
    expect(Money.parseAmount('abc'), 0);
  });

  testWidgets('MoneyText prints two decimals only for fractional amounts',
      (WidgetTester tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(Builder(builder: (BuildContext c) {
      ctx = c;
      return const SizedBox();
    }));
    expect(MoneyText.digits(ctx, 93.2), '93.20');
    expect(MoneyText.digits(ctx, 1065), '1,065');
    expect(MoneyText.digits(ctx, 12345.5), '12,345.50');
    expect(MoneyText.plain(ctx, 466), 'SAR 466');
  });
}
