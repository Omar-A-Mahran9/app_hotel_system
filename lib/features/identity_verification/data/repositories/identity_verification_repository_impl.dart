import '../../../../core/errors/error_mapper.dart';
import '../../domain/entities/identity_document.dart';
import '../../domain/entities/identity_verification_request.dart';
import '../../domain/entities/identity_verification_session.dart';
import '../../domain/repositories/identity_verification_repository.dart';
import '../datasources/identity_verification_data_source.dart';

/// Coordinates the identity-verification data source and maps DTO models to
/// domain entities. Which [IdentityVerificationDataSource] it holds (dummy vs
/// API) is a DI decision, not made here. Every data-layer error is mapped to a
/// `Failure` via [ErrorMapper] so the presentation layer only handles the
/// user-safe type — no provider or storage detail leaks.
class IdentityVerificationRepositoryImpl
    implements IdentityVerificationRepository {
  IdentityVerificationRepositoryImpl(this._dataSource);

  final IdentityVerificationDataSource _dataSource;

  @override
  Future<IdentityVerificationSession> statusFor(String reservationId) =>
      _guard(() async =>
          (await _dataSource.fetchStatus(reservationId)).toEntity());

  @override
  Future<List<IdentityDocumentOption>> documentTypes() =>
      _guard(() => _dataSource.documentTypes());

  @override
  Future<IdentityVerificationSession> submitDocument(
    SubmitIdentityDocumentRequest request, {
    void Function(double fraction)? onProgress,
  }) =>
      _guard(() async => (await _dataSource.submitDocument(
            request,
            onProgress: onProgress,
          ))
              .toEntity());

  @override
  Future<IdentityVerificationSession> submitSelfie(
    SubmitSelfieRequest request, {
    void Function(double fraction)? onProgress,
  }) =>
      _guard(() async => (await _dataSource.submitSelfie(
            request,
            onProgress: onProgress,
          ))
              .toEntity());

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (error) {
      throw ErrorMapper.toFailure(error);
    }
  }
}
