import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_document.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_verification_request.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_verification_session.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_verification_status.dart';

void main() {
  group('IdentityVerificationStatus', () {
    test('every value round-trips through its wire value', () {
      for (final s in IdentityVerificationStatus.values) {
        expect(IdentityVerificationStatus.fromWire(s.wireValue), s);
      }
    });

    test('wire values match the Laravel session constants', () {
      expect(IdentityVerificationStatus.notStarted.wireValue, 'not_started');
      expect(IdentityVerificationStatus.matchingInProgress.wireValue,
          'matching_in_progress');
      expect(IdentityVerificationStatus.autoApproved.wireValue, 'auto_approved');
      expect(IdentityVerificationStatus.pendingManualReview.wireValue,
          'pending_manual_review');
      expect(IdentityVerificationStatus.retryAllowed.wireValue, 'retry_allowed');
    });

    test('an unknown value falls back to notStarted', () {
      expect(IdentityVerificationStatus.fromWire('???'),
          IdentityVerificationStatus.notStarted);
    });

    test('approved is a positive list (auto + staff)', () {
      expect(IdentityVerificationStatus.autoApproved.isApproved, isTrue);
      expect(IdentityVerificationStatus.staffApproved.isApproved, isTrue);
      expect(IdentityVerificationStatus.staffRejected.isApproved, isFalse);
      expect(IdentityVerificationStatus.pendingManualReview.isApproved, isFalse);
    });

    test('only auto/staff approved are terminal — staffRejected is not', () {
      expect(IdentityVerificationStatus.autoApproved.isTerminal, isTrue);
      expect(IdentityVerificationStatus.staffApproved.isTerminal, isTrue);
      expect(IdentityVerificationStatus.staffRejected.isTerminal, isFalse);
    });

    test('step predicates route the UI', () {
      expect(IdentityVerificationStatus.notStarted.needsDocument, isTrue);
      expect(IdentityVerificationStatus.retryAllowed.needsDocument, isTrue);
      expect(IdentityVerificationStatus.staffRejected.needsDocument, isTrue);
      expect(IdentityVerificationStatus.documentUploaded.needsSelfie, isTrue);
      expect(IdentityVerificationStatus.selfieCaptured.isProcessing, isTrue);
      expect(IdentityVerificationStatus.matchingInProgress.isProcessing, isTrue);
    });

    test('allowsRetry only from retryAllowed / staffRejected', () {
      expect(IdentityVerificationStatus.retryAllowed.allowsRetry, isTrue);
      expect(IdentityVerificationStatus.staffRejected.allowsRetry, isTrue);
      expect(IdentityVerificationStatus.autoApproved.allowsRetry, isFalse);
      expect(IdentityVerificationStatus.pendingManualReview.allowsRetry, isFalse);
    });
  });

  group('IdentityVerificationSession', () {
    test('notStarted factory + derived getters', () {
      final s = IdentityVerificationSession.notStarted('res-1');
      expect(s.status, IdentityVerificationStatus.notStarted);
      expect(s.needsDocument, isTrue);
      expect(s.canRetry, isFalse);
      expect(s.isResolved, isFalse);
    });

    test('copyWith preserves the reservation id', () {
      final s = IdentityVerificationSession.notStarted('res-1')
          .copyWith(status: IdentityVerificationStatus.autoApproved, attempts: 2);
      expect(s.reservationId, 'res-1');
      expect(s.isApproved, isTrue);
      expect(s.attempts, 2);
    });

    test('manual review is resolved but not approved', () {
      final s = IdentityVerificationSession.notStarted('res-1')
          .copyWith(status: IdentityVerificationStatus.pendingManualReview);
      expect(s.isResolved, isTrue);
      expect(s.isApproved, isFalse);
      expect(s.isManualReview, isTrue);
    });
  });

  group('requests', () {
    test('document request key is stable, no time/random', () {
      const a = SubmitIdentityDocumentRequest(
        reservationId: 'res-1',
        type: IdentityDocumentType.passport,
        image: CapturedImage.dummy,
      );
      const b = SubmitIdentityDocumentRequest(
        reservationId: 'res-1',
        type: IdentityDocumentType.passport,
        image: CapturedImage.dummy,
      );
      expect(a.idempotencyKey, b.idempotencyKey);
      expect(a, b);
    });

    test('selfie request key is per-reservation and stable', () {
      const a = SubmitSelfieRequest(
          reservationId: 'res-1', image: CapturedImage.dummy);
      expect(a.idempotencyKey, 'idv-selfie:res-1');
      expect(a,
          const SubmitSelfieRequest(reservationId: 'res-1', image: CapturedImage.dummy));
    });

    test('CapturedImage carries no bytes — only safe metadata', () {
      const img = CapturedImage.dummy;
      expect(img.toString(), isNot(contains('bytes:')));
      expect(img.sizeBytes, greaterThan(0));
    });
  });

  group('IdentityDocumentType', () {
    test('round-trips through wire values', () {
      for (final t in IdentityDocumentType.values) {
        expect(IdentityDocumentType.fromWire(t.wireValue), t);
      }
    });
  });
}
