import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/localization/content_language_provider.dart';
import 'package:hotel_guest_app/core/localization/locale_controller.dart';
import 'package:hotel_guest_app/core/localization/supported_locales.dart';
import 'package:hotel_guest_app/core/network/interceptors/locale_interceptor.dart';

class _RecordingAdapter implements HttpClientAdapter {
  final List<RequestOptions> received = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    received.add(options);
    return ResponseBody.fromString(
      jsonEncode(<String, dynamic>{'data': null}),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('sends the current app language as X-Locale on every request', () async {
    String language = 'ar';
    final _RecordingAdapter adapter = _RecordingAdapter();
    final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
      ..httpClientAdapter = adapter
      ..interceptors.add(LocaleInterceptor(() => language));

    await dio.get<dynamic>('/guest/hotels');
    language = 'en';
    await dio.get<dynamic>('/guest/hotels');

    expect(adapter.received[0].headers['X-Locale'], 'ar');
    expect(adapter.received[0].headers['Accept-Language'], 'ar');
    expect(adapter.received[1].headers['X-Locale'], 'en');
  });

  test('content language follows the chosen locale (Arabic by default)', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(contentLanguageProvider), 'ar');

    container.read(localeControllerProvider.notifier).set(SupportedLocales.english);
    expect(container.read(contentLanguageProvider), 'en');
  });
}
