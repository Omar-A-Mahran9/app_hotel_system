import 'package:flutter/foundation.dart';

import 'problem_category.dart';
import 'problem_urgency.dart';

/// A request to submit a problem report for a reservation. The backend
/// resolves ownership, the hotel and the initial `open` status
/// (`SubmitProblemReportRequest` — category/urgency/notes are the only
/// client-supplied fields).
@immutable
class SubmitProblemReportRequest {
  const SubmitProblemReportRequest({
    required this.reservationId,
    required this.category,
    required this.urgency,
    this.notes,
  });

  final String reservationId;
  final ProblemCategory category;
  final ProblemUrgency urgency;
  final String? notes;

  /// Stable key for local duplicate-submit dedupe. Category/urgency/notes are
  /// part of it so an edited report is a distinct operation; no time/random.
  String get idempotencyKey => <String>[
        'problem',
        reservationId,
        category.wireValue,
        urgency.wireValue,
        notes ?? '-',
      ].join('|');

  @override
  bool operator ==(Object other) =>
      other is SubmitProblemReportRequest &&
      other.reservationId == reservationId &&
      other.category == category &&
      other.urgency == urgency &&
      other.notes == notes;

  @override
  int get hashCode => Object.hash(reservationId, category, urgency, notes);

  @override
  String toString() => 'SubmitProblemReportRequest($idempotencyKey)';
}
