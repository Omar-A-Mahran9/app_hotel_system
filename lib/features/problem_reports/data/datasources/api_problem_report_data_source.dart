import '../../../../core/data/data_source.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/problem_report.dart';
import '../../domain/entities/submit_problem_report.dart';
import '../models/problem_report_models.dart';
import 'problem_report_data_source.dart';

/// API-backed problem-reports source.
///
/// Real, authenticated guest contract (`auth:guest`), reservation-scoped:
/// `GET  /guest/reservations/{reservation}/problems` → paginated
/// `GuestProblemReportResource` list;
/// `POST /guest/reservations/{reservation}/problems`
/// (`{category, urgency, notes?}`) → 201 `GuestProblemReportResource`;
/// `GET  /guest/reservations/{reservation}/problems/{problem}` → 200 | 404
/// (not found or not owned — no existence leak, same convention as every
/// other reservation-scoped guest endpoint).
///
/// Ownership, the hotel and the initial `open` status are all resolved
/// server-side — the client only ever supplies category/urgency/notes.
class ApiProblemReportDataSource
    implements ProblemReportDataSource, RemoteDataSource {
  ApiProblemReportDataSource(this._client);

  final ApiClient _client;

  @override
  Future<List<ProblemReport>> fetchList(String reservationId) async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/reservations/$reservationId/problems',
    );
    final List<Object?> rows = (json['data'] as List<Object?>?) ?? const <Object?>[];
    return rows
        .whereType<Map<String, Object?>>()
        .map((Map<String, Object?> row) => ProblemReportModel(row).toEntity())
        .toList(growable: false);
  }

  @override
  Future<ProblemReport> fetchById(String reservationId, String reportId) async {
    final Map<String, dynamic> json = await _client.getJson(
      '/guest/reservations/$reservationId/problems/$reportId',
    );
    final Map<String, Object?> data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
    return ProblemReportModel(data).toEntity();
  }

  @override
  Future<ProblemReport> submit(SubmitProblemReportRequest request) async {
    final Map<String, dynamic> json = await _client.postJson(
      '/guest/reservations/${request.reservationId}/problems',
      body: SubmitProblemReportPayload.fromRequest(request).toJson(),
    );
    final Map<String, Object?> data =
        (json['data'] as Map<String, Object?>?) ?? const <String, Object?>{};
    return ProblemReportModel(data).toEntity();
  }
}
