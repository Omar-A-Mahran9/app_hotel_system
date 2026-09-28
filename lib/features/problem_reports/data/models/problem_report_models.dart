// Data-transfer models for the problem-reports feature.
//
// Mirrors `GuestProblemReportResource` exactly: `id`, `reservation_id`,
// `category`, `urgency`, `notes`, `status`, `resolved_at`, `created_at`.

import '../../domain/entities/problem_category.dart';
import '../../domain/entities/problem_report.dart';
import '../../domain/entities/problem_report_status.dart';
import '../../domain/entities/problem_urgency.dart';
import '../../domain/entities/submit_problem_report.dart';

typedef Json = Map<String, Object?>;

DateTime? _dateOrNull(Object? raw) {
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  return null;
}

class ProblemReportModel {
  const ProblemReportModel(this._json);
  final Json _json;

  ProblemReport toEntity() {
    final Object? rawNotes = _json['notes'];
    final String? notes = rawNotes is String && rawNotes.trim().isNotEmpty
        ? rawNotes.trim()
        : null;
    return ProblemReport(
      id: '${_json['id']}',
      reservationId: '${_json['reservation_id']}',
      category: ProblemCategory.fromWire(_json['category'] as String?),
      urgency: ProblemUrgency.fromWire(_json['urgency'] as String?),
      notes: notes,
      status: ProblemReportStatus.fromWire(_json['status'] as String?),
      createdAt:
          _dateOrNull(_json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      resolvedAt: _dateOrNull(_json['resolved_at']),
    );
  }
}

/// The submit request body — matches `SubmitProblemReportRequest`'s rules
/// (`category`, `urgency` required; `notes` optional).
class SubmitProblemReportPayload {
  const SubmitProblemReportPayload({
    required this.category,
    required this.urgency,
    this.notes,
  });

  factory SubmitProblemReportPayload.fromRequest(
    SubmitProblemReportRequest r,
  ) =>
      SubmitProblemReportPayload(
        category: r.category,
        urgency: r.urgency,
        notes: r.notes,
      );

  final ProblemCategory category;
  final ProblemUrgency urgency;
  final String? notes;

  Json toJson() => <String, Object?>{
        'category': category.wireValue,
        'urgency': urgency.wireValue,
        if (notes != null) 'notes': notes,
      };
}
