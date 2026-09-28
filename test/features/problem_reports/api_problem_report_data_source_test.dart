import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/network/interceptors/error_interceptor.dart';
import 'package:hotel_guest_app/features/problem_reports/data/datasources/api_problem_report_data_source.dart';
import 'package:hotel_guest_app/features/problem_reports/domain/entities/problem_category.dart';
import 'package:hotel_guest_app/features/problem_reports/domain/entities/problem_report_status.dart';
import 'package:hotel_guest_app/features/problem_reports/domain/entities/problem_urgency.dart';
import 'package:hotel_guest_app/features/problem_reports/domain/entities/submit_problem_report.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.routes);

  final Map<String, (int, Map<String, dynamic>)> routes;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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

ApiProblemReportDataSource _source(_FakeAdapter adapter) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
    ..httpClientAdapter = adapter
    ..interceptors.add(ErrorInterceptor());
  return ApiProblemReportDataSource(ApiClient.withDio(dio));
}

void main() {
  test('fetchList maps the guest-report resource list', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/reservations/45/problems': (200, <String, dynamic>{
        'success': true,
        'message': 'ok',
        'data': <dynamic>[
          <String, dynamic>{
            'id': 1184,
            'reservation_id': 45,
            'category': 'ac_heating',
            'urgency': 'important',
            'notes': null,
            'status': 'open',
            'resolved_at': null,
            'created_at': '2026-09-12T09:41:00.000000Z',
          },
        ],
      }),
    });

    final reports = await _source(adapter).fetchList('45');
    expect(reports, hasLength(1));
    expect(reports.single.id, '1184');
    expect(reports.single.category, ProblemCategory.acHeating);
  });

  test('fetchById maps a single report', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/reservations/45/problems/1184': (200, <String, dynamic>{
        'success': true,
        'message': 'ok',
        'data': <String, dynamic>{
          'id': 1184,
          'reservation_id': 45,
          'category': 'plumbing_water',
          'urgency': 'normal',
          'notes': 'Slow drain',
          'status': 'in_progress',
          'resolved_at': null,
          'created_at': '2026-09-12T09:41:00.000000Z',
        },
      }),
    });

    final report = await _source(adapter).fetchById('45', '1184');
    expect(report.category, ProblemCategory.plumbingWater);
    expect(report.status, ProblemReportStatus.inProgress);
    expect(report.notes, 'Slow drain');
  });

  test('fetchById surfaces a 404 (not owned / missing)', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/reservations/45/problems/999': (404, <String, dynamic>{
        'success': false,
        'message': 'Not found',
      }),
    });

    // The interceptor normalizes the failed response into a `DioException`
    // whose `.error` carries the classified `AppException` — the same shape
    // `ErrorMapper` (and every repository's `_guard`) consumes.
    await expectLater(
      _source(adapter).fetchById('45', '999'),
      throwsA(
        isA<DioException>().having((e) => e.error, 'error', isA<NotFoundException>()),
      ),
    );
  });

  test('submit posts category/urgency/notes and maps the 201 response', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/45/problems': (201, <String, dynamic>{
        'success': true,
        'message': 'Submitted',
        'data': <String, dynamic>{
          'id': 1185,
          'reservation_id': 45,
          'category': 'noise_disturbance',
          'urgency': 'urgent',
          'notes': 'Loud music next door',
          'status': 'open',
          'resolved_at': null,
          'created_at': '2026-09-12T09:41:00.000000Z',
        },
      }),
    });

    final report = await _source(adapter).submit(
      const SubmitProblemReportRequest(
        reservationId: '45',
        category: ProblemCategory.noiseDisturbance,
        urgency: ProblemUrgency.urgent,
        notes: 'Loud music next door',
      ),
    );

    expect(report.id, '1185');
    expect(report.status, ProblemReportStatus.open);
    expect(report.urgency, ProblemUrgency.urgent);
  });

  test('submit surfaces a 422 as a validation failure', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/45/problems': (422, <String, dynamic>{
        'success': false,
        'message': 'The given data was invalid.',
        'errors': <String, dynamic>{
          'category': <String>['The selected category is invalid.'],
        },
      }),
    });

    await expectLater(
      _source(adapter).submit(
        const SubmitProblemReportRequest(
          reservationId: '45',
          category: ProblemCategory.noiseDisturbance,
          urgency: ProblemUrgency.normal,
        ),
      ),
      throwsA(
        isA<DioException>().having((e) => e.error, 'error', isA<ValidationException>()),
      ),
    );
  });
}
