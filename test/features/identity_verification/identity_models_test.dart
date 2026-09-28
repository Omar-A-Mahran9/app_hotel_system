import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/identity_verification/data/models/identity_verification_models.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_document.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_verification_request.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_verification_session.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_verification_status.dart';

void main() {
  test('IdentityDocumentPayload mirrors the documented document_type field', () {
    const req = SubmitIdentityDocumentRequest(
      reservationId: 'r1',
      type: IdentityDocumentType.egyptianNationalId,
      image: CapturedImage.dummy,
    );
    final fields = IdentityDocumentPayload.fromRequest(req).toFields();
    expect(fields, <String, Object?>{'document_type': 'egyptian_national_id'});
  });

  test('SessionModel.fromJson maps an IdentityVerificationResource payload', () {
    final model = IdentityVerificationSessionModel.fromJson(<String, Object?>{
      'reservation_id': 7,
      'hotel_id': 3,
      'guest_id': 5,
      'status': 'pending_manual_review',
      'provider': 'dummy',
      'attempts': 2,
      'latest_outcome': 'inconclusive',
      'latest_score': 55,
      'decided_at': null,
      'created_at': '2026-09-01T09:00:00.000',
    });
    final entity = model.toEntity();
    expect(entity.reservationId, '7');
    expect(entity.status, IdentityVerificationStatus.pendingManualReview);
    expect(entity.attempts, 2);
    expect(entity.latestOutcome, IdentityMatchOutcome.inconclusive);
  });

  test('an unknown status maps to notStarted defensively', () {
    final model = IdentityVerificationSessionModel.fromJson(<String, Object?>{
      'reservation_id': 1,
      'status': 'huh',
    });
    expect(model.toEntity().status, IdentityVerificationStatus.notStarted);
  });

  test('does not surface score / provider / storage detail on the entity', () {
    final model = IdentityVerificationSessionModel.fromJson(<String, Object?>{
      'reservation_id': 1,
      'status': 'auto_approved',
      'latest_score': 99,
      'provider': 'acme',
    });
    final s = model.toEntity();
    expect(s.toString(), isNot(contains('99')));
    expect(s.toString().toLowerCase(), isNot(contains('acme')));
  });
}
