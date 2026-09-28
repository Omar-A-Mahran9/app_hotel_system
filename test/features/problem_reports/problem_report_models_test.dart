import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/problem_reports/data/models/problem_report_models.dart';
import 'package:hotel_guest_app/features/problem_reports/domain/entities/problem_category.dart';
import 'package:hotel_guest_app/features/problem_reports/domain/entities/problem_report_status.dart';
import 'package:hotel_guest_app/features/problem_reports/domain/entities/problem_urgency.dart';
import 'package:hotel_guest_app/features/problem_reports/domain/entities/submit_problem_report.dart';

void main() {
  group('ProblemCategory.fromWire', () {
    test('round-trips every backend-catalogue value exactly', () {
      const Map<String, ProblemCategory> wire = <String, ProblemCategory>{
        'ac_heating': ProblemCategory.acHeating,
        'plumbing_water': ProblemCategory.plumbingWater,
        'electricity_lighting': ProblemCategory.electricityLighting,
        'room_cleanliness': ProblemCategory.roomCleanliness,
        'internet_wifi': ProblemCategory.internetWifi,
        'noise_disturbance': ProblemCategory.noiseDisturbance,
      };
      wire.forEach((String w, ProblemCategory c) {
        expect(ProblemCategory.fromWire(w), c);
        expect(c.wireValue, w);
      });
    });

    test('an unrecognised value falls back to acHeating (never null)', () {
      expect(ProblemCategory.fromWire('not_a_real_category'), ProblemCategory.acHeating);
      expect(ProblemCategory.fromWire(null), ProblemCategory.acHeating);
    });
  });

  group('ProblemUrgency.fromWire', () {
    test('round-trips normal/important/urgent', () {
      expect(ProblemUrgency.fromWire('normal'), ProblemUrgency.normal);
      expect(ProblemUrgency.fromWire('important'), ProblemUrgency.important);
      expect(ProblemUrgency.fromWire('urgent'), ProblemUrgency.urgent);
    });

    test('an unrecognised value falls back to normal', () {
      expect(ProblemUrgency.fromWire('whatever'), ProblemUrgency.normal);
    });
  });

  group('ProblemReportStatus.fromWire', () {
    test('round-trips open/in_progress/resolved', () {
      expect(ProblemReportStatus.fromWire('open'), ProblemReportStatus.open);
      expect(ProblemReportStatus.fromWire('in_progress'), ProblemReportStatus.inProgress);
      expect(ProblemReportStatus.fromWire('resolved'), ProblemReportStatus.resolved);
    });

    test('an unrecognised value falls back to open', () {
      expect(ProblemReportStatus.fromWire('bogus'), ProblemReportStatus.open);
    });
  });

  group('ProblemReportModel', () {
    test('maps the guest-report resource shape', () {
      final report = ProblemReportModel(<String, Object?>{
        'id': 1184,
        'reservation_id': 45,
        'category': 'ac_heating',
        'urgency': 'important',
        'notes': '  AC has not been cooling since yesterday.  ',
        'status': 'open',
        'resolved_at': null,
        'created_at': '2026-09-12T09:41:00.000000Z',
      }).toEntity();

      expect(report.id, '1184');
      expect(report.reservationId, '45');
      expect(report.category, ProblemCategory.acHeating);
      expect(report.urgency, ProblemUrgency.important);
      expect(report.notes, 'AC has not been cooling since yesterday.'); // trimmed
      expect(report.status, ProblemReportStatus.open);
      expect(report.resolvedAt, isNull);
      expect(report.createdAt, isNotNull);
      expect(report.reference, 'IS-1184');
    });

    test('blank notes become null; resolved_at parses when present', () {
      final report = ProblemReportModel(<String, Object?>{
        'id': 2,
        'reservation_id': 9,
        'category': 'plumbing_water',
        'urgency': 'normal',
        'notes': '   ',
        'status': 'resolved',
        'resolved_at': '2026-09-11T08:00:00.000000Z',
        'created_at': '2026-09-10T08:00:00.000000Z',
      }).toEntity();

      expect(report.notes, isNull);
      expect(report.hasNotes, isFalse);
      expect(report.resolvedAt, isNotNull);
    });
  });

  group('SubmitProblemReportPayload', () {
    test('sends category + urgency; omits notes when absent', () {
      const SubmitProblemReportRequest withNotes = SubmitProblemReportRequest(
        reservationId: '1',
        category: ProblemCategory.noiseDisturbance,
        urgency: ProblemUrgency.urgent,
        notes: 'Loud party next door',
      );
      expect(
        SubmitProblemReportPayload.fromRequest(withNotes).toJson(),
        <String, Object?>{
          'category': 'noise_disturbance',
          'urgency': 'urgent',
          'notes': 'Loud party next door',
        },
      );

      const SubmitProblemReportRequest withoutNotes = SubmitProblemReportRequest(
        reservationId: '1',
        category: ProblemCategory.internetWifi,
        urgency: ProblemUrgency.normal,
      );
      expect(
        SubmitProblemReportPayload.fromRequest(withoutNotes).toJson(),
        <String, Object?>{'category': 'internet_wifi', 'urgency': 'normal'},
      );
    });
  });
}
