import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/problem_reports/data/datasources/dummy_problem_report_data_source.dart';
import 'package:hotel_guest_app/features/problem_reports/domain/entities/problem_category.dart';
import 'package:hotel_guest_app/features/problem_reports/domain/entities/problem_report_status.dart';
import 'package:hotel_guest_app/features/problem_reports/domain/entities/problem_urgency.dart';
import 'package:hotel_guest_app/features/problem_reports/domain/entities/submit_problem_report.dart';

/// The first reservation id (`RES0`, `RES1`, …) mapping to [scenario].
String _scenarioId(DummyProblemReportScenario scenario) {
  for (int i = 0; i < 4000; i++) {
    final String id = 'RES$i';
    if (DummyProblemReportDataSource.scenarioFor(id) == scenario) return id;
  }
  throw StateError('no reservation id found for $scenario');
}

void main() {
  final DateTime now = DateTime(2026, 9, 12, 9, 41);
  DummyProblemReportDataSource source() =>
      DummyProblemReportDataSource(clock: () => now);

  SubmitProblemReportRequest req(
    String reservationId, {
    ProblemCategory category = ProblemCategory.acHeating,
    ProblemUrgency urgency = ProblemUrgency.important,
    String? notes,
  }) =>
      SubmitProblemReportRequest(
        reservationId: reservationId,
        category: category,
        urgency: urgency,
        notes: notes,
      );

  group('DummyProblemReportDataSource — seeded history', () {
    test('a fresh reservation with no prior reports lists empty', () async {
      final id = _scenarioId(DummyProblemReportScenario.none);
      expect(await source().fetchList(id), isEmpty);
    });

    test('a reservation seeded with an in-progress report lists it', () async {
      final id = _scenarioId(DummyProblemReportScenario.onePriorInProgress);
      final reports = await source().fetchList(id);
      expect(reports, hasLength(1));
      expect(reports.single.status, ProblemReportStatus.inProgress);
    });

    test('a reservation seeded with a resolved report lists it', () async {
      final id = _scenarioId(DummyProblemReportScenario.onePriorResolved);
      final reports = await source().fetchList(id);
      expect(reports, hasLength(1));
      expect(reports.single.status, ProblemReportStatus.resolved);
      expect(reports.single.resolvedAt, isNotNull);
    });
  });

  group('DummyProblemReportDataSource — submit', () {
    test('a new report always starts open and is echoed back', () async {
      final id = _scenarioId(DummyProblemReportScenario.none);
      final s = source();
      final report = await s.submit(req(id, notes: 'Fan is very loud'));

      expect(report.reservationId, id);
      expect(report.category, ProblemCategory.acHeating);
      expect(report.urgency, ProblemUrgency.important);
      expect(report.notes, 'Fan is very loud');
      expect(report.status, ProblemReportStatus.open);
      expect(report.createdAt, now);
    });

    test('ids increment across submissions and appear in the list', () async {
      final id = _scenarioId(DummyProblemReportScenario.none);
      final s = source();
      final first = await s.submit(req(id, category: ProblemCategory.plumbingWater));
      final second = await s.submit(req(id, category: ProblemCategory.electricityLighting));

      expect(first.id, isNot(second.id));
      final list = await s.fetchList(id);
      expect(list.map((r) => r.id), containsAll(<String>[first.id, second.id]));
    });

    test('a repeat of the same request is idempotent (no duplicate)', () async {
      final id = _scenarioId(DummyProblemReportScenario.none);
      final s = source();
      final request = req(id, notes: 'Slow drain');
      final first = await s.submit(request);
      final second = await s.submit(request);

      expect(second.id, first.id);
      expect(await s.fetchList(id), hasLength(1));
    });

    test('submitting for a reservation with seeded history adds to it', () async {
      final id = _scenarioId(DummyProblemReportScenario.onePriorResolved);
      final s = source();
      await s.submit(req(id));
      expect(await s.fetchList(id), hasLength(2));
    });
  });

  group('DummyProblemReportDataSource — fetchById', () {
    test('finds a freshly created report by id', () async {
      final id = _scenarioId(DummyProblemReportScenario.none);
      final s = source();
      final created = await s.submit(req(id));
      final fetched = await s.fetchById(id, created.id);
      expect(fetched, created);
    });

    test('finds a seeded report by id', () async {
      final id = _scenarioId(DummyProblemReportScenario.onePriorInProgress);
      final s = source();
      final list = await s.fetchList(id);
      final fetched = await s.fetchById(id, list.single.id);
      expect(fetched, list.single);
    });

    test('an unknown report id throws NotFoundException', () async {
      final id = _scenarioId(DummyProblemReportScenario.none);
      await expectLater(
        source().fetchById(id, 'does-not-exist'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('DummyProblemReportDataSource — failWith seam', () {
    test('surfaces the error from every method', () async {
      final s = source()..failWith = const NetworkException();
      await expectLater(s.fetchList('x'), throwsA(isA<NetworkException>()));
      await expectLater(s.fetchById('x', 'y'), throwsA(isA<NetworkException>()));
      await expectLater(s.submit(req('x')), throwsA(isA<NetworkException>()));
    });
  });
}
