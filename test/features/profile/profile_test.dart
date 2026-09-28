import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/app/router/app_routes.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/network/interceptors/error_interceptor.dart';
import 'package:hotel_guest_app/features/profile/data/datasources/api_profile_data_source.dart';
import 'package:hotel_guest_app/features/profile/domain/entities/guest_preferences.dart';
import 'package:hotel_guest_app/features/profile/presentation/state/profile_providers.dart';

import '../../support/auth_test_support.dart';
import '../../support/pump_app.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);

  final Map<String, Map<String, dynamic>> routes;
  final List<(String, Object?)> calls = <(String, Object?)>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String key = '${options.method} ${options.path}';
    calls.add((key, options.data));
    return ResponseBody.fromString(
      jsonEncode(routes[key] ?? <String, dynamic>{'success': false}),
      routes.containsKey(key) ? 200 : 404,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _guest({bool highFloor = false, String? deletionAt}) => <String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'guest': <String, dynamic>{
          'id': 1,
          'preferences': <String, dynamic>{
            'high_floor': highFloor,
            'extra_pillows': false,
            'notifications_enabled': true,
          },
          'data_deletion_requested_at': deletionAt,
        },
      },
    };

Future<ProviderContainer> _openAccount(WidgetTester tester) async {
  final ProviderContainer container =
      await pumpApp(tester, bootSession: completeSession());
  container.read(appRouterProvider).goNamed(AppRoutes.accountName);
  await tester.pumpAndSettle();
  return container;
}

void main() {
  test('API source reads and writes the guest preferences + privacy state', () async {
    final _FakeAdapter adapter = _FakeAdapter(<String, Map<String, dynamic>>{
      'GET /guest/auth/me': _guest(),
      'PATCH /guest/preferences': _guest(highFloor: true),
      'POST /guest/privacy/deletion-request':
          _guest(deletionAt: '2026-09-25T10:00:00.000000Z'),
    });
    final ApiProfileDataSource source = ApiProfileDataSource(
      ApiClient.withDio(
        Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
          ..httpClientAdapter = adapter
          ..interceptors.add(ErrorInterceptor()),
      ),
    );

    expect((await source.fetchSettings()).preferences, GuestPreferences.defaults);
    final GuestAccountSettings saved = await source.savePreferences(
      GuestPreferences.defaults.copyWith(highFloor: true),
    );
    expect(saved.preferences.highFloor, isTrue);
    expect(adapter.calls[1].$2, <String, dynamic>{
      'high_floor': true,
      'extra_pillows': false,
      'notifications_enabled': true,
    });
    expect((await source.requestDataDeletion()).dataDeletionRequestedAt, isNotNull);
  });

  testWidgets('every account row opens its own screen', (WidgetTester tester) async {
    final en = await tester.l10n();
    await _openAccount(tester);

    for (final (String row, String title) in <(String, String)>[
      (en.accountPreferencesLabel, en.profilePreferencesBannerTitle),
      (en.accountPrivacyLabel, en.profilePrivacyBannerTitle),
      (en.accountHelpSupportLabel, en.profileSupportBannerTitle),
      (en.authSignOut, en.profileLogoutConfirmTitle),
    ]) {
      await tester.tap(find.text(row).first);
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget, reason: row);
      await _leave(tester);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('preferences toggle a draft and save it to the server',
      (WidgetTester tester) async {
    final en = await tester.l10n();
    final ProviderContainer container = await _openAccount(tester);
    await tester.tap(find.text(en.accountPreferencesLabel));
    await tester.pumpAndSettle();

    final Finder save = find.widgetWithText(FilledButton, en.profileSave);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.tap(find.text(en.profilePrefHighFloor));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
    await tester.tap(save);
    await tester.pumpAndSettle();

    final GuestAccountSettings stored =
        await container.read(profileRepositoryProvider).settings();
    expect(stored.preferences.highFloor, isTrue);
    expect(find.text(en.profileSaved), findsOneWidget);
  });

  testWidgets('a data deletion request is confirmed, sent and then shown as sent',
      (WidgetTester tester) async {
    final en = await tester.l10n();
    final ProviderContainer container = await _openAccount(tester);
    await tester.tap(find.text(en.accountPrivacyLabel));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, en.profileRequestDeletion));
    await tester.pumpAndSettle();
    expect(find.text(en.profileDeletionConfirmTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.profileDeletionConfirmCta));
    await tester.pumpAndSettle();

    expect(find.text(en.profileDeletionRequestedTitle), findsOneWidget);
    final FilledButton cta = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, en.profileDeletionRequestedCta),
    );
    expect(cta.onPressed, isNull);
    expect(
      (await container.read(profileRepositoryProvider).settings()).dataDeletionRequestedAt,
      isNotNull,
    );
  });

  testWidgets('support opens the FAQ, and with a stay reaches reception + reporting',
      (WidgetTester tester) async {
    final en = await tester.l10n();
    await _openAccount(tester);
    await tester.tap(find.text(en.accountHelpSupportLabel));
    await tester.pumpAndSettle();

    // The dummy bookings include a stay, so both stay actions are live.
    expect(find.text(en.profileDuringStayOnly), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, en.identityContactReceptionCta));
    await tester.pumpAndSettle();
    expect(find.text(en.identityContactReceptionBannerTitle), findsOneWidget);
    await _leave(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text(en.profileFaq));
    await tester.pumpAndSettle();
    expect(find.text(en.profileFaqEmptyTitle), findsOneWidget);
  });
}

/// Leaves a sub-screen: the back arrow, or the ✕ on the v2 banner screens
/// (logout confirm, contact reception).
Future<void> _leave(WidgetTester tester) async {
  final Finder close = find.byTooltip('Close');
  if (close.evaluate().isNotEmpty) {
    await tester.tap(close.first);
  } else {
    await tester.pageBack();
  }
}
