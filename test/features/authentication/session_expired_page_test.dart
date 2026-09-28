import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/features/authentication/presentation/state/auth_controller.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';

void main() {
  testWidgets('an expired session shows the reassurance banner and re-entry',
      (WidgetTester tester) async {
    final ProviderContainer container =
        await pumpApp(tester, bootSession: completeSession());

    await container.read(authControllerProvider.notifier).expireSession();
    await tester.pumpAndSettle();

    final AppLocalizations en = await tester.l10n();
    expect(find.text(en.authSessionExpiredBannerTitle), findsOneWidget);
    expect(find.text(en.authSessionExpiredSubmit), findsOneWidget);
  });

  testWidgets('re-entry from the expired screen returns to the entry screen',
      (WidgetTester tester) async {
    final ProviderContainer container =
        await pumpApp(tester, bootSession: completeSession());
    await container.read(authControllerProvider.notifier).expireSession();
    await tester.pumpAndSettle();

    final AppLocalizations en = await tester.l10n();
    await tester.tap(find.text(en.authSessionExpiredSubmit));
    await tester.pumpAndSettle();

    expect(find.text(en.entryHeadline), findsOneWidget);
  });
}
