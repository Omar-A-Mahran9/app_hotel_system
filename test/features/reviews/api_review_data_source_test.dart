import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/network/interceptors/error_interceptor.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';
import 'package:hotel_guest_app/features/reviews/data/datasources/api_review_data_source.dart';
import 'package:hotel_guest_app/features/reviews/domain/entities/review_category.dart';
import 'package:hotel_guest_app/features/reviews/domain/entities/review_draft.dart';
import 'package:hotel_guest_app/features/reviews/domain/entities/submit_review.dart';

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
        routes[key] ??
        (404, <String, dynamic>{'success': false, 'message': 'no route $key'});
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

ApiReviewDataSource _source(_FakeAdapter adapter) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
    ..httpClientAdapter = adapter
    ..interceptors.add(ErrorInterceptor());
  return ApiReviewDataSource(ApiClient.withDio(dio));
}

const ReviewContext _ctx = ReviewContext(
  reservationId: '9',
  reservationStatus: ReservationStatus.checkedOut,
);

void main() {
  dynamicCategoryTests();

  test('fetchReview returns null on 404 (no review yet)', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/reservations/9/review': (
        404,
        <String, dynamic>{'success': false, 'message': 'Not found'},
      ),
    });

    expect(await _source(adapter).fetchReview(_ctx), isNull);
  });

  test('submit maps a 201 to submitted', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/9/review': (
        201,
        <String, dynamic>{
          'success': true,
          'message': 'Submitted',
          'data': <String, dynamic>{
            'id': 3,
            'reservation_id': 9,
            'rating': 5,
            'text': 'Great stay',
            'status': 'pending',
          },
        },
      ),
    });

    final result = await _source(adapter).submit(
      const SubmitReviewRequest(
        reservationId: '9',
        rating: 5,
        text: 'Great stay',
      ),
      _ctx,
    );

    expect(result.outcome, ReviewSubmitOutcome.submitted);
    expect(result.review!.status.isPending, isTrue);
  });

  test('submit maps a 200 duplicate replay to alreadyReviewed', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/9/review': (
        200,
        <String, dynamic>{
          'success': true,
          'message': 'Already reviewed',
          'data': <String, dynamic>{
            'id': 3,
            'reservation_id': 9,
            'rating': 5,
            'text': 'Great stay',
            'status': 'published',
          },
        },
      ),
    });

    final result = await _source(adapter).submit(
      const SubmitReviewRequest(
        reservationId: '9',
        rating: 5,
        text: 'Great stay',
      ),
      _ctx,
    );

    expect(result.outcome, ReviewSubmitOutcome.alreadyReviewed);
  });

  test('submit maps a reservation_not_completed 422 to notEligible', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/9/review': (
        422,
        <String, dynamic>{
          'success': false,
          'message': 'This review action is not allowed.',
          'errors': <String, dynamic>{
            'reason': 'reservation_not_completed:verified',
          },
        },
      ),
    });

    final result = await _source(adapter)
        .submit(const SubmitReviewRequest(reservationId: '9', rating: 5), _ctx);

    expect(result.outcome, ReviewSubmitOutcome.notEligible);
  });
}

/// Dynamic review categories — nothing about them is known to the app; the
/// ids/labels below are arbitrary to prove it.
void dynamicCategoryTests() {
  const ReviewContext hotelCtx = ReviewContext(
    reservationId: '9',
    reservationStatus: ReservationStatus.checkedOut,
    hotelId: '42',
  );

  test('fetchCategories reads the hotel\'s categories in API order', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'GET /guest/hotels/42/review-categories': (
        200,
        <String, dynamic>{
          'success': true,
          'data': <dynamic>[
            <String, dynamic>{
              'id': 19,
              'label': 'Pool',
              'icon': 'waves',
              'description': null,
            },
            <String, dynamic>{
              'id': 12,
              'label': 'Staff',
              'icon': null,
              'description': 'Friendly?',
            },
            <String, dynamic>{'id': 77, 'label': 'Noise'},
          ],
        },
      ),
    });

    final List<ReviewCategory> categories = await _source(adapter)
        .fetchCategories(hotelCtx);

    expect(categories.map((ReviewCategory c) => c.id), <String>[
      '19',
      '12',
      '77',
    ]);
    expect(categories.map((ReviewCategory c) => c.label), <String>[
      'Pool',
      'Staff',
      'Noise',
    ]);
    expect(categories.first.icon, 'waves');
    expect(categories[1].description, 'Friendly?');
  });

  test(
    'fetchCategories is empty for a hotel with none, without a hotel id',
    () async {
      final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
        'GET /guest/hotels/42/review-categories': (
          200,
          <String, dynamic>{'success': true, 'data': <dynamic>[]},
        ),
      });
      expect(await _source(adapter).fetchCategories(hotelCtx), isEmpty);
      expect(await _source(adapter).fetchCategories(_ctx), isEmpty);
      expect(adapter.received.length, 1);
    },
  );

  test(
    'submit sends category_ratings and reads them back (snapshot labels)',
    () async {
      final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
        'POST /guest/reservations/9/review': (
          201,
          <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{
              'id': 5,
              'reservation_id': 9,
              'rating': 4,
              'text': null,
              'status': 'pending',
              'created_at': '2026-09-24T10:00:00Z',
              'category_ratings': <dynamic>[
                <String, dynamic>{
                  'category_id': 19,
                  'label': 'Pool',
                  'rating': 5,
                },
                <String, dynamic>{
                  'category_id': 77,
                  'label': 'Noise',
                  'rating': 3,
                },
              ],
            },
          },
        ),
      });

      final SubmitReviewResult result = await _source(adapter).submit(
        const SubmitReviewRequest(
          reservationId: '9',
          rating: 4,
          categoryRatings: <String, int>{'19': 5, '77': 3},
        ),
        hotelCtx,
      );

      final Object? body = adapter.received.single.data;
      expect(body, isA<Map<String, Object?>>());
      final List<Object?> sent =
          (body! as Map<String, Object?>)['category_ratings']! as List<Object?>;
      expect(
        sent,
        containsAll(<Object?>[
          <String, Object?>{'category_id': 19, 'rating': 5},
          <String, Object?>{'category_id': 77, 'rating': 3},
        ]),
      );
      expect(result.outcome, ReviewSubmitOutcome.submitted);
      expect(
        result.review!.categoryRatings.map((ReviewCategoryRating r) => r.label),
        <String>['Pool', 'Noise'],
      );
      expect(result.review!.categoryRatings.first.rating, 5);
    },
  );

  test('submit omits category_ratings when none were given', () async {
    final adapter = _FakeAdapter(<String, (int, Map<String, dynamic>)>{
      'POST /guest/reservations/9/review': (
        201,
        <String, dynamic>{
          'success': true,
          'data': <String, dynamic>{
            'id': 6,
            'reservation_id': 9,
            'rating': 5,
            'status': 'pending',
          },
        },
      ),
    });
    await _source(adapter).submit(
      const SubmitReviewRequest(reservationId: '9', rating: 5),
      hotelCtx,
    );
    expect(
      (adapter.received.single.data as Map<String, Object?>).containsKey(
        'category_ratings',
      ),
      isFalse,
    );
  });
}
