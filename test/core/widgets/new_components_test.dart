import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/theme/app_theme.dart';
import 'package:hotel_guest_app/core/widgets/app_card.dart';
import 'package:hotel_guest_app/core/widgets/app_icon_button.dart';
import 'package:hotel_guest_app/core/widgets/app_list_row.dart';
import 'package:hotel_guest_app/core/widgets/section_header.dart';

Future<void> _pump(WidgetTester tester, Widget child, TextDirection dir) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: dir,
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  for (final dir in TextDirection.values) {
    testWidgets('design-system components render without exception ($dir)',
        (WidgetTester tester) async {
      await _pump(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SectionHeader(title: 'Section', action: 'All', onAction: () {}),
            AppIconButton(icon: Icons.search, onPressed: () {}),
            AppIconButton(
              icon: Icons.star,
              onPressed: () {},
              selected: true,
              style: AppIconButtonStyle.dark,
            ),
            for (final style in AppCardStyle.values)
              AppCard(
                style: style,
                child: const AppListRow(
                  label: 'Label',
                  value: Text('Value'),
                ),
              ),
            const AppListRow(
              label: 'Total',
              value: Text('99'),
              style: AppListRowStyle.total,
            ),
          ],
        ),
        dir,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
