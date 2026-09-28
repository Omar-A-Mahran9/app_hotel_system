import '../../../../core/data/data_source.dart';
import '../../domain/entities/identity_document.dart';
import '../../domain/entities/identity_document_check.dart';
import '../../domain/entities/identity_verification_request.dart';
import '../../domain/entities/identity_verification_session.dart';
import '../../domain/entities/identity_verification_status.dart';
import '../models/identity_verification_models.dart';
import 'identity_verification_data_source.dart';

/// A deterministic match scenario, chosen purely from the reservation id so the
/// same reservation always behaves the same way. No randomness, no time-derived
/// branching.
enum DummyVerificationScenario {
  /// `AUTO_APPROVED` on the first selfie.
  autoApprove,

  /// `PENDING_MANUAL_REVIEW` — a staff member decides.
  manualReview,

  /// `RETRY_ALLOWED` on the first attempt (selfie didn't match the document —
  /// `low_match`); `AUTO_APPROVED` on the second.
  retryThenApprove,

  /// `RETRY_ALLOWED` on the first attempt (the document itself could not be
  /// read — provider `error`); `AUTO_APPROVED` on the second.
  retryUnclearThenApprove,

  /// `STAFF_REJECTED` on the first attempt (a completed rejecting review);
  /// `PENDING_MANUAL_REVIEW` on a further attempt.
  rejectThenReview,
}

/// Deterministic, offline identity-verification source used while no
/// guest-facing contract is approved.
///
/// Guarantees required by the phase brief:
/// * no network, no timers, no randomness, no artificial delays;
/// * the resolved status is a pure function of the reservation id (via
///   [scenarioFor]) and the attempt count;
/// * the session walks the approved state machine
///   (`NOT_STARTED → DOCUMENT_UPLOADED → SELFIE_CAPTURED →
///   MATCHING_IN_PROGRESS → …`) — no state is invented;
/// * it never holds image bytes: submissions carry only a [CapturedImage]
///   descriptor, which is not stored or logged here.
///
/// It performs NO OCR: dummy mode is the offline demo / test source. Every
/// document upload returns a `verified` document check unless a test sets
/// [nextDocumentCheck] (e.g. to exercise the mismatch / expired / unreadable
/// screens). Real OCR only ever happens on the backend.
///
/// [failWith] is a test seam (mirrors `DummyReservationDataSource.failWith`).
class DummyIdentityVerificationDataSource
    implements IdentityVerificationDataSource, DummyDataSource {
  DummyIdentityVerificationDataSource({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, IdentityVerificationSession> _sessions =
      <String, IdentityVerificationSession>{};

  /// When non-null, the next call throws this instead.
  Object? failWith;

  /// Test seam: the document-check status the next upload resolves to.
  DocumentCheckStatus? nextDocumentCheck;

  /// The deterministic scenario for a reservation id.
  static DummyVerificationScenario scenarioFor(String reservationId) {
    switch (_fnv1a(reservationId) % 5) {
      case 0:
        return DummyVerificationScenario.autoApprove;
      case 1:
        return DummyVerificationScenario.manualReview;
      case 2:
        return DummyVerificationScenario.retryThenApprove;
      case 3:
        return DummyVerificationScenario.retryUnclearThenApprove;
      default:
        return DummyVerificationScenario.rejectThenReview;
    }
  }

  IdentityVerificationSession _current(String reservationId) =>
      _sessions[reservationId] ??
      IdentityVerificationSession.notStarted(reservationId);

  IdentityVerificationSessionModel _model(IdentityVerificationSession s) {
    return IdentityVerificationSessionModel.fromJson(<String, Object?>{
      'reservation_id': s.reservationId,
      'status': s.status.wireValue,
      'attempts': s.attempts,
      'latest_outcome': switch (s.latestOutcome) {
        IdentityMatchOutcome.match => 'high_match',
        IdentityMatchOutcome.faceNotMatched => 'low_match',
        IdentityMatchOutcome.documentUnclear => 'error',
        IdentityMatchOutcome.inconclusive => 'inconclusive',
        IdentityMatchOutcome.unknown => null,
      },
      'decided_at': s.decidedAt?.toIso8601String(),
      if (s.documentCheck != null)
        'document_check': <String, Object?>{
          'status': s.documentCheck!.status.wireValue,
          'reasons': s.documentCheck!.reasons,
          'fields': s.documentCheck!.fields,
          'can_continue': s.documentCheck!.canContinue,
          'requires_new_document': s.documentCheck!.requiresNewDocument,
        },
    });
  }

  @override
  Future<IdentityVerificationSessionModel> fetchStatus(
    String reservationId,
  ) async {
    if (failWith != null) throw failWith!;
    return _model(_current(reservationId));
  }

  @override
  Future<List<IdentityDocumentOption>> documentTypes() async {
    if (failWith != null) throw failWith!;
    return IdentityDocumentOption.defaults;
  }

  @override
  Future<IdentityVerificationSessionModel> submitDocument(
    SubmitIdentityDocumentRequest request, {
    UploadProgress? onProgress,
  }) async {
    if (failWith != null) throw failWith!;
    onProgress?.call(1);

    final IdentityVerificationSession current = _current(request.reservationId);
    if (!current.needsDocument &&
        current.status != IdentityVerificationStatus.documentUploaded) {
      // Nothing to do from here (already past the document step) — return the
      // current state rather than an invalid transition.
      return _model(current);
    }

    final DocumentCheckStatus check =
        nextDocumentCheck ?? DocumentCheckStatus.verified;
    nextDocumentCheck = null;
    final IdentityVerificationSession next = IdentityVerificationSession(
      reservationId: current.reservationId,
      status: IdentityVerificationStatus.documentUploaded,
      attempts: current.attempts,
      latestOutcome: current.latestOutcome,
      decidedAt: current.decidedAt,
      documentCheck: DocumentCheck(
        status: check,
        canContinue: check == DocumentCheckStatus.verified ||
            check == DocumentCheckStatus.needsReview,
        requiresNewDocument: check != DocumentCheckStatus.verified &&
            check != DocumentCheckStatus.needsReview,
        fields: check == DocumentCheckStatus.mismatch
            ? const <String, String>{'number': 'mismatch'}
            : const <String, String>{},
      ),
    );
    _sessions[request.reservationId] = next;
    return _model(next);
  }

  @override
  Future<IdentityVerificationSessionModel> submitSelfie(
    SubmitSelfieRequest request, {
    UploadProgress? onProgress,
  }) async {
    if (failWith != null) throw failWith!;
    onProgress?.call(1);

    final IdentityVerificationSession current = _current(request.reservationId);
    // Mirrors the backend: no selfie while the document check blocks it.
    if (current.documentRejected) return _model(current);
    if (current.status != IdentityVerificationStatus.documentUploaded &&
        current.status != IdentityVerificationStatus.selfieCaptured) {
      // A repeat submit from an already-resolved state is a no-op — the guest
      // must go through `retry` to start a fresh attempt.
      return _model(current);
    }

    final int attempts = current.attempts + 1;
    final IdentityVerificationStatus resolved =
        _resolve(request.reservationId, attempts);
    final IdentityVerificationSession next = current.copyWith(
      status: resolved,
      attempts: attempts,
      latestOutcome: _outcomeFor(request.reservationId, resolved),
      decidedAt: resolved.isApproved ||
              resolved == IdentityVerificationStatus.staffRejected
          ? _clock()
          : null,
    );
    _sessions[request.reservationId] = next;
    return _model(next);
  }

  IdentityVerificationStatus _resolve(String reservationId, int attempts) {
    return switch (scenarioFor(reservationId)) {
      DummyVerificationScenario.autoApprove =>
        IdentityVerificationStatus.autoApproved,
      DummyVerificationScenario.manualReview =>
        IdentityVerificationStatus.pendingManualReview,
      DummyVerificationScenario.retryThenApprove ||
      DummyVerificationScenario.retryUnclearThenApprove =>
        attempts <= 1
            ? IdentityVerificationStatus.retryAllowed
            : IdentityVerificationStatus.autoApproved,
      DummyVerificationScenario.rejectThenReview => attempts <= 1
          ? IdentityVerificationStatus.staffRejected
          : IdentityVerificationStatus.pendingManualReview,
    };
  }

  static IdentityMatchOutcome _outcomeFor(
    String reservationId,
    IdentityVerificationStatus status,
  ) =>
      switch (status) {
        IdentityVerificationStatus.autoApproved ||
        IdentityVerificationStatus.staffApproved =>
          IdentityMatchOutcome.match,
        IdentityVerificationStatus.retryAllowed =>
          scenarioFor(reservationId) ==
                  DummyVerificationScenario.retryUnclearThenApprove
              ? IdentityMatchOutcome.documentUnclear
              : IdentityMatchOutcome.faceNotMatched,
        IdentityVerificationStatus.staffRejected =>
          IdentityMatchOutcome.faceNotMatched,
        IdentityVerificationStatus.pendingManualReview =>
          IdentityMatchOutcome.inconclusive,
        _ => IdentityMatchOutcome.unknown,
      };

  static int _fnv1a(String value) {
    int hash = 0x811c9dc5;
    for (final int unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
