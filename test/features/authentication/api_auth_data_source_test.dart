import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/network/interceptors/error_interceptor.dart';
import 'package:hotel_guest_app/features/authentication/data/datasources/api_auth_data_source.dart';
import 'package:hotel_guest_app/features/authentication/data/models/auth_models.dart';

/// Canned-response adapter: maps `METHOD path` to a (status, jsonBody) pair.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);

  final Map<String, (int, Map<String, dynamic>)> routes;
  final List<RequestOptions> received = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    received.add(options);
    final String key = '${options.method} ${options.path}';
    final (int, Map<String, dynamic>) entry =
        routes[key] ?? (404, <String, dynamic>{'success': false, 'message': 'no route $key'});
    return ResponseBody.fromString(
      jsonEncode(entry.$2),
      entry.$1,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiAuthDataSource _source(_FakeAdapter adapter) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
    ..httpClientAdapter = adapter
    ..interceptors.add(ErrorInterceptor());
  return ApiAuthDataSource(ApiClient.withDio(dio));
}

void main() {
  test('requestOtp parses the challenge', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/auth/otp/request': (200, <String, dynamic>{
        'success': true,
        'message': 'sent',
        'data': <String, dynamic>{
          'challenge_id': 'c-1',
          'phone': '+966500000000',
          'code_length': 6,
          'attempts_remaining': 5,
          'expires_in': 300,
          'resend_available_in': 42,
        },
      }),
    });

    final OtpChallengeModel c = await _source(adapter).requestOtp('+966500000000');

    expect(c.challengeId, 'c-1');
    expect(c.attemptsRemaining, 5);
    expect(adapter.received.single.data, <String, dynamic>{
      'phone': '+966500000000',
    });
  });

  test('verifyOtp maps the authenticated outcome to an accepted session', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/auth/otp/verify': (200, <String, dynamic>{
        'success': true,
        'message': 'ok',
        'data': <String, dynamic>{
          'outcome': 'authenticated',
          'token': '42|abcdef',
          'guest': <String, dynamic>{'id': 1, 'name': null, 'email': null, 'phone': '+966500000000'},
          'profile_complete': false,
        },
      }),
    });

    final OtpVerifyResult r = await _source(adapter).verifyOtp(
      challengeId: 'c-1',
      phoneE164: '+966500000000',
      attemptsRemaining: 5,
      code: '123456',
    );

    expect(r, isA<OtpVerifyAccepted>());
    expect((r as OtpVerifyAccepted).session.accessToken, '42|abcdef');
  });

  test('verifyOtp maps rejected / locked_out outcomes', () async {
    final rejected = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/auth/otp/verify': (200, <String, dynamic>{
        'success': true,
        'message': 'wrong',
        'data': <String, dynamic>{'outcome': 'rejected', 'attempts_remaining': 3},
      }),
    });
    final r1 = await _source(rejected).verifyOtp(
      challengeId: 'c', phoneE164: '+9665', attemptsRemaining: 4, code: '000000');
    expect((r1 as OtpVerifyRejected).attemptsRemaining, 3);

    final locked = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/auth/otp/verify': (200, <String, dynamic>{
        'success': true,
        'message': 'locked',
        'data': <String, dynamic>{'outcome': 'locked_out', 'attempts_remaining': 0},
      }),
    });
    expect(
      await _source(locked).verifyOtp(
        challengeId: 'c', phoneE164: '+9665', attemptsRemaining: 1, code: '000000'),
      isA<OtpVerifyLockedOut>(),
    );
  });

  test('fetchCurrentSession returns null on 401', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/auth/me': (401, <String, dynamic>{'success': false, 'message': 'Unauthenticated.'}),
    });

    expect(await _source(adapter).fetchCurrentSession('stale'), isNull);
  });

  test('fetchCurrentSession rebuilds the session on 200', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/auth/me': (200, <String, dynamic>{
        'success': true,
        'message': 'OK',
        'data': <String, dynamic>{
          'guest': <String, dynamic>{'id': 1, 'name': 'Sara', 'email': 's@e.com', 'phone': '+966500000000'},
          'profile_complete': true,
        },
      }),
    });

    final AuthSessionModel? s = await _source(adapter).fetchCurrentSession('t');
    expect(s!.fullName, 'Sara');
    expect(s.phoneE164, '+966500000000');
  });

  test('completeProfile PATCHes name + email', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'PATCH /guest/profile': (200, <String, dynamic>{
        'success': true,
        'message': 'Updated',
        'data': <String, dynamic>{
          'guest': <String, dynamic>{'id': 1, 'name': 'Sara', 'email': 's@e.com', 'phone': '+966500000000'},
          'profile_complete': true,
        },
      }),
    });

    final AuthSessionModel s = await _source(adapter).completeProfile(
      accessToken: 'tok', phoneE164: '+966500000000', fullName: 'Sara', email: 's@e.com');

    expect(s.email, 's@e.com');
    expect(adapter.received.single.data,
        <String, dynamic>{'name': 'Sara', 'email': 's@e.com'});
  });
}
