import '../../../../core/data/data_source.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/problem_category.dart';
import '../../domain/entities/problem_report.dart';
import '../../domain/entities/problem_report_status.dart';
import '../../domain/entities/problem_urgency.dart';
import '../../domain/entities/submit_problem_report.dart';
import 'problem_report_data_source.dart';

/// A deterministic seeded-history scenario, chosen purely from the
/// reservation id — so a reservation's problem-report history looks the same
/// every run without a backend.
enum DummyProblemReportScenario {
  /// No prior reports.
  none,

  /// One prior report still being worked.
  onePriorInProgress,

  /// One prior report already resolved.
  onePriorResolved,
}

/// Deterministic, offline problem-reports source used while
/// `AppConfig.useDummyData` is `true`.
///
/// Guarantees required by the phase brief:
/// * no network, no timers, no randomness, no `DateTime.now()` branching (a
///   `clock` is injected for timestamps only);
/// * seeded history is a pure function of the reservation id
///   ([scenarioFor]);
/// * [submit] is idempotent per request — a repeat of the same
///   [SubmitProblemReportRequest] returns the report already created, never a
///   duplicate;
/// * a newly created report always starts `open` — the app never invents a
///   later status for its own just-submitted report.
///
/// [failWith] is a test seam.
class DummyProblemReportDataSource
    implements ProblemReportDataSource, DummyDataSource {
  DummyProblemReportDataSource({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// reservationId -> reports created this session (seeded history is
  /// generated on demand and not stored here).
  final Map<String, List<ProblemReport>> _created = <String, List<ProblemReport>>{};
  final Map<String, String> _idByKey = <String, String>{};

  /// Starts past the Figma reference sample (`#IS-1184`) so freshly created
  /// reports read as plausible continuations of it.
  int _nextId = 1185;

  Object? failWith;

  static DummyProblemReportScenario scenarioFor(String reservationId) {
    switch (_fnv1a(reservationId) % 3) {
      case 0:
        return DummyProblemReportScenario.none;
      case 1:
        return DummyProblemReportScenario.onePriorInProgress;
      default:
        return DummyProblemReportScenario.onePriorResolved;
    }
  }

  List<ProblemReport> _seeded(String reservationId) {
    switch (scenarioFor(reservationId)) {
      case DummyProblemReportScenario.none:
        return const <ProblemReport>[];
      case DummyProblemReportScenario.onePriorInProgress:
        return <ProblemReport>[
          ProblemReport(
            id: 'seed-$reservationId',
            reservationId: reservationId,
            category: ProblemCategory.acHeating,
            urgency: ProblemUrgency.important,
            notes: 'AC has not been cooling since yesterday.',
            status: ProblemReportStatus.inProgress,
            createdAt: _clock().subtract(const Duration(hours: 3)),
          ),
        ];
      case DummyProblemReportScenario.onePriorResolved:
        return <ProblemReport>[
          ProblemReport(
            id: 'seed-$reservationId',
            reservationId: reservationId,
            category: ProblemCategory.plumbingWater,
            urgency: ProblemUrgency.normal,
            notes: null,
            status: ProblemReportStatus.resolved,
            createdAt: _clock().subtract(const Duration(days: 1)),
            resolvedAt: _clock().subtract(const Duration(hours: 20)),
          ),
        ];
    }
  }

  List<ProblemReport> _all(String reservationId) => <ProblemReport>[
        ...(_created[reservationId] ?? const <ProblemReport>[]),
        ..._seeded(reservationId),
      ];

  ProblemReport? _findById(String reservationId, String reportId) {
    for (final ProblemReport r in _all(reservationId)) {
      if (r.id == reportId) return r;
    }
    return null;
  }

  @override
  Future<List<ProblemReport>> fetchList(String reservationId) async {
    if (failWith != null) throw failWith!;
    final List<ProblemReport> reports = _all(reservationId)
      ..sort((ProblemReport a, ProblemReport b) => b.createdAt.compareTo(a.createdAt));
    return reports;
  }

  @override
  Future<ProblemReport> fetchById(String reservationId, String reportId) async {
    if (failWith != null) throw failWith!;
    final ProblemReport? found = _findById(reservationId, reportId);
    if (found == null) {
      throw NotFoundException('No problem report "$reportId"');
    }
    return found;
  }

  @override
  Future<ProblemReport> submit(SubmitProblemReportRequest request) async {
    if (failWith != null) throw failWith!;

    final String? existingId = _idByKey[request.idempotencyKey];
    if (existingId != null) {
      final ProblemReport? existing = _findById(request.reservationId, existingId);
      if (existing != null) return existing;
    }

    final String id = '${_nextId++}';
    final ProblemReport report = ProblemReport(
      id: id,
      reservationId: request.reservationId,
      category: request.category,
      urgency: request.urgency,
      notes: request.notes,
      status: ProblemReportStatus.open,
      createdAt: _clock(),
    );

    final List<ProblemReport> list =
        List<ProblemReport>.of(_created[request.reservationId] ?? const <ProblemReport>[])
          ..add(report);
    _created[request.reservationId] = list;
    _idByKey[request.idempotencyKey] = id;
    return report;
  }

  static int _fnv1a(String value) {
    int hash = 0x811c9dc5;
    for (final int unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
