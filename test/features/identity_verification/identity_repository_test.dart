import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/core/errors/failure.dart';
import 'package:hotel_guest_app/features/identity_verification/data/datasources/dummy_identity_verification_data_source.dart';
import 'package:hotel_guest_app/features/identity_verification/data/datasources/identity_verification_data_source.dart';
import 'package:hotel_guest_app/features/identity_verification/data/models/identity_verification_models.dart';
import 'package:hotel_guest_app/features/identity_verification/data/repositories/identity_verification_repository_impl.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_document.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_verification_request.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_verification_status.dart';

import 'identity_test_support.dart';

class _ThrowingSource implements IdentityVerificationDataSource {
  const _ThrowingSource(this.error);
  final Object error;

  @override
  Future<IdentityVerificationSessionModel> fetchStatus(String r) async =>
      throw error;
  @override
  Future<List<IdentityDocumentOption>> documentTypes() async => throw error;
  @override
  Future<IdentityVerificationSessionModel> submitDocument(
          SubmitIdentityDocumentRequest r,
          {UploadProgress? onProgress}) async =>
      throw error;
  @override
  Future<IdentityVerificationSessionModel> submitSelfie(
          SubmitSelfieRequest r,
          {UploadProgress? onProgress}) async =>
      throw error;
}

void main() {
  const doc = SubmitIdentityDocumentRequest(
    reservationId: 'r1',
    type: IdentityDocumentType.passport,
    image: CapturedImage.dummy,
  );

  test('maps dummy models to domain entities through the flow', () async {
    final id = reservationIdForScenario(DummyVerificationScenario.autoApprove);
    final repo = IdentityVerificationRepositoryImpl(
      DummyIdentityVerificationDataSource(clock: () => DateTime(2026, 9, 8)),
    );
    expect((await repo.statusFor(id)).status,
        IdentityVerificationStatus.notStarted);
    await repo.submitDocument(SubmitIdentityDocumentRequest(
      reservationId: id,
      type: IdentityDocumentType.passport,
      image: CapturedImage.dummy,
    ));
    final resolved = await repo.submitSelfie(
      SubmitSelfieRequest(reservationId: id, image: CapturedImage.dummy),
    );
    expect(resolved.isApproved, isTrue);
  });

  test('a NotImplemented stub becomes a notImplemented Failure', () async {
    final repo = IdentityVerificationRepositoryImpl(
      const _ThrowingSource(NotImplementedInPhaseException('x')),
    );
    await expectLater(
      repo.submitDocument(doc),
      throwsA(isA<Failure>()
          .having((f) => f.kind, 'kind', FailureKind.notImplemented)),
    );
  });

  test('an arbitrary error is mapped to a Failure, not leaked raw', () async {
    final repo = IdentityVerificationRepositoryImpl(
      const _ThrowingSource(FormatException('boom')),
    );
    await expectLater(repo.statusFor('x'), throwsA(isA<Failure>()));
  });
}
