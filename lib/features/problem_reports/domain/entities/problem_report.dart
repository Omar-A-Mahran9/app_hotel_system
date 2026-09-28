import 'package:flutter/foundation.dart';

import 'problem_category.dart';
import 'problem_report_status.dart';
import 'problem_urgency.dart';

/// A guest's in-stay problem report, mirroring the safe guest-facing fields
/// of `GuestProblemReportResource` (`id`, `reservation_id`, `category`,
/// `urgency`, `notes`, `status`, `resolved_at`, `created_at`).
///
/// Unlike [Review] (one per completed stay), a reservation may have many
/// reports (`mobile/Design/13 · Report a problem.png`).
@immutable
class ProblemReport {
  const ProblemReport({
    required this.id,
    required this.reservationId,
    required this.category,
    required this.urgency,
    required this.status,
    required this.createdAt,
    this.notes,
    this.resolvedAt,
  });

  final String id;
  final String reservationId;
  final ProblemCategory category;
  final ProblemUrgency urgency;

  /// Optional free text. Never whitespace-only (trimmed at the boundary).
  final String? notes;

  final ProblemReportStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  /// A short human reference for the "submitted" screen (`IS-1184`).
  String get reference => 'IS-$id';

  bool get hasNotes => notes != null && notes!.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is ProblemReport &&
      other.id == id &&
      other.reservationId == reservationId &&
      other.category == category &&
      other.urgency == urgency &&
      other.notes == notes &&
      other.status == status &&
      other.createdAt == createdAt &&
      other.resolvedAt == resolvedAt;

  @override
  int get hashCode => Object.hash(
        id,
        reservationId,
        category,
        urgency,
        notes,
        status,
        createdAt,
        resolvedAt,
      );

  @override
  String toString() => 'ProblemReport($reference, ${status.wireValue})';
}
