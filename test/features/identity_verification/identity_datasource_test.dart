import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/identity_verification/data/datasources/dummy_identity_verification_data_source.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_document.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_verification_request.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_verification_status.dart';

import 'identity_test_support.dart';

void main() {
  final now = DateTime(2026, 9, 8, 9, 41);

  DummyIdentityVerificationDataSource source() =>
      DummyIdentityVerificationDataSource(clock: () => now);

  SubmitIdentityDocumentRequest doc(String id) => SubmitIdentityDocumentRequest(
        reservationId: id,
        type: IdentityDocumentType.passport,
        image: CapturedImage.dummy,
      );
  SubmitSelfieRequest selfie(String id) =>
      SubmitSelfieRequest(reservationId: id, image: CapturedImage.dummy);

  Future<IdentityVerificationStatus> walkToSelfie(
    DummyIdentityVerificationDataSource s,
    String id,
  ) async {
    await s.submitDocument(doc(id));
    return (await s.submitSelfie(selfie(id))).toEntity().status;
  }

  group('DummyIdentityVerificationDataSource', () {
    test('scenario is a pure function of the reservation id', () {
      final id = reservationIdForScenario(DummyVerificationScenario.autoApprove);
      expect(DummyIdentityVerificationDataSource.scenarioFor(id),
          DummyVerificationScenario.autoApprove);
    });

    test('fresh session is NOT_STARTED', () async {
      final m = await source().fetchStatus('unknown');
      expect(m.toEntity().status, IdentityVerificationStatus.notStarted);
    });

    test('walks the state machine: document → selfie → resolved', () async {
      final id = reservationIdForScenario(DummyVerificationScenario.autoApprove);
      final s = source();
      final afterDoc = await s.submitDocument(doc(id));
      expect(afterDoc.toEntity().status,
          IdentityVerificationStatus.documentUploaded);
      final afterSelfie = await s.submitSelfie(selfie(id));
      expect(afterSelfie.toEntity().status,
          IdentityVerificationStatus.autoApproved);
      expect(afterSelfie.toEntity().attempts, 1);
    });

    test('autoApprove scenario → AUTO_APPROVED', () async {
      final id = reservationIdForScenario(DummyVerificationScenario.autoApprove);
      expect(await walkToSelfie(source(), id),
          IdentityVerificationStatus.autoApproved);
    });

    test('manualReview scenario → PENDING_MANUAL_REVIEW', () async {
      final id = reservationIdForScenario(DummyVerificationScenario.manualReview);
      expect(await walkToSelfie(source(), id),
          IdentityVerificationStatus.pendingManualReview);
    });

    test('retryThenApprove: RETRY_ALLOWED, then a fresh attempt → APPROVED',
        () async {
      final id =
          reservationIdForScenario(DummyVerificationScenario.retryThenApprove);
      final s = source();
      expect(await walkToSelfie(s, id),
          IdentityVerificationStatus.retryAllowed);

      // Retry = re-submit the document from RETRY_ALLOWED, then the selfie.
      await s.submitDocument(doc(id));
      final resolved = await s.submitSelfie(selfie(id));
      expect(resolved.toEntity().status,
          IdentityVerificationStatus.autoApproved);
      expect(resolved.toEntity().attempts, 2);
    });

    test('rejectThenReview: STAFF_REJECTED, then a fresh attempt → REVIEW',
        () async {
      final id =
          reservationIdForScenario(DummyVerificationScenario.rejectThenReview);
      final s = source();
      expect(await walkToSelfie(s, id),
          IdentityVerificationStatus.staffRejected);

      await s.submitDocument(doc(id));
      final resolved = await s.submitSelfie(selfie(id));
      expect(resolved.toEntity().status,
          IdentityVerificationStatus.pendingManualReview);
    });

    test('a repeat selfie from a resolved state is a no-op (no extra attempt)',
        () async {
      final id =
          reservationIdForScenario(DummyVerificationScenario.retryThenApprove);
      final s = source();
      await walkToSelfie(s, id); // RETRY_ALLOWED, attempts = 1
      final again = await s.submitSelfie(selfie(id));
      expect(again.toEntity().status, IdentityVerificationStatus.retryAllowed);
      expect(again.toEntity().attempts, 1);
    });

    test('failWith seam surfaces an error from every method', () async {
      final s = source()..failWith = const NetworkException();
      await expectLater(s.fetchStatus('x'), throwsA(isA<NetworkException>()));
      await expectLater(
          s.submitDocument(doc('x')), throwsA(isA<NetworkException>()));
      await expectLater(
          s.submitSelfie(selfie('x')), throwsA(isA<NetworkException>()));
    });
  });

  // `ApiIdentityVerificationDataSource` is now real for `fetchStatus`; the
  // upload methods still refuse without a real camera/file-picker capture
  // (no `CapturedImage.filePath`) — see
  // test/features/identity_verification/api_identity_verification_data_source_test.dart.
}
