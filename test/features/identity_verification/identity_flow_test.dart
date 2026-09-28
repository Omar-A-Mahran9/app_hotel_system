import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/app/router/app_router.dart';
import 'package:hotel_guest_app/core/localization/generated/app_localizations.dart';
import 'package:hotel_guest_app/core/errors/app_exception.dart';
import 'package:hotel_guest_app/features/identity_verification/data/datasources/dummy_identity_verification_data_source.dart';
import 'package:hotel_guest_app/features/identity_verification/data/datasources/identity_verification_data_source.dart';
import 'package:hotel_guest_app/features/identity_verification/data/models/identity_verification_models.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_verification_request.dart';
import 'package:hotel_guest_app/features/identity_verification/data/device/identity_camera.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_document.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_document_check.dart';
import 'package:hotel_guest_app/features/identity_verification/presentation/state/identity_verification_providers.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/extend_stay.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';
import 'package:hotel_guest_app/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:hotel_guest_app/features/reservation/presentation/state/reservation_providers.dart';

import '../../support/auth_test_support.dart';
import '../../support/fake_identity_camera.dart';
import '../../support/pump_app.dart';
import '../payment/payment_test_support.dart' show fakeReservation;
import 'identity_test_support.dart';

class _StubReservationRepository implements ReservationRepository {
  @override
  Future<Reservation> create(CreateReservationRequest request) async =>
      fakeReservation(status: ReservationStatus.depositHeld);
  @override
  Future<Reservation> getById(String id) async =>
      fakeReservation(id: id, status: ReservationStatus.depositHeld);
  @override
  Future<List<Reservation>> list() async => <Reservation>[];

  @override
  Future<Reservation> cancel(String id) async => fakeReservation(id: id);

  @override
  Future<ExtendStayResult> extend(ExtendStayRequest request) async {
    throw UnimplementedError('extend not used in this test');
  }
}


/// Records every document request (to assert front/back and the claim).
class _RecordingSource extends DummyIdentityVerificationDataSource {
  final List<SubmitIdentityDocumentRequest> requests = <SubmitIdentityDocumentRequest>[];

  @override
  Future<IdentityVerificationSessionModel> submitDocument(
    SubmitIdentityDocumentRequest request, {
    UploadProgress? onProgress,
  }) {
    requests.add(request);
    return super.submitDocument(request, onProgress: onProgress);
  }
}

/// Holds the upload open so the progress / "reading" states can be seen.
class _GatedSource extends DummyIdentityVerificationDataSource {
  final Completer<void> sent = Completer<void>();
  final Completer<void> read = Completer<void>();

  @override
  Future<IdentityVerificationSessionModel> submitDocument(
    SubmitIdentityDocumentRequest request, {
    UploadProgress? onProgress,
  }) async {
    onProgress?.call(0.4);
    await sent.future;
    onProgress?.call(1);
    await read.future;
    return super.submitDocument(request, onProgress: null);
  }
}

const Key _shutterButton = ValueKey('identityShutterButton');

Future<AppLocalizations> _l10n(String code) =>
    AppLocalizations.delegate.load(Locale(code));

Future<void> _open(
  WidgetTester tester,
  String id, {
  Locale? locale,
  FakeIdentityCamera? camera,
  DummyIdentityVerificationDataSource? source,
}) async {
  final c = await pumpApp(
    tester,
    bootSession: completeSession(),
    locale: locale,
    extraOverrides: <Override>[
      reservationRepositoryProvider
          .overrideWithValue(_StubReservationRepository()),
      if (camera != null) identityCameraProvider.overrideWithValue(camera),
      if (source != null)
        identityVerificationDataSourceProvider.overrideWithValue(source),
    ],
  );
  c.read(appRouterProvider).go('/reservation/$id/identity');
  await tester.pumpAndSettle();
}

/// Capture (tap the shutter) + confirm the ID review step — the two taps that
/// call `submitDocument`.
Future<void> _captureAndSubmitDocument(WidgetTester tester, AppLocalizations l10n) async {
  await tester.tap(find.byKey(_shutterButton));
  await tester.pumpAndSettle();
  // Card types ask for the back as a second shot.
  if (find.text(l10n.identityCaptureBackTitle).evaluate().isNotEmpty) {
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();
  }
  await tester
      .tap(find.widgetWithText(FilledButton, l10n.identityReviewContinueCta));
  await tester.pumpAndSettle();
  // "Document accepted" / "manual review" → continue to the selfie.
  if (find.text(l10n.identityDocumentAcceptedTitle).evaluate().isNotEmpty ||
      find.text(l10n.identityDocumentReviewTitle).evaluate().isNotEmpty) {
    await tester
        .tap(find.widgetWithText(FilledButton, l10n.identityReviewContinueCta));
    await tester.pumpAndSettle();
  }
}

/// The selfie step submits on capture — no separate review step.
Future<void> _captureSelfie(WidgetTester tester) async {
  await tester.tap(find.byKey(_shutterButton));
  await tester.pumpAndSettle();
}

/// Intro → ID details form (filled and confirmed) → document capture.
Future<void> _dismissIntro(WidgetTester tester, AppLocalizations l10n) async {
  await tester.tap(find.widgetWithText(FilledButton, l10n.identityIntroCta));
  await tester.pumpAndSettle();
  await _fillDetails(tester, l10n);
}

/// Fills the ID details form with SYNTHETIC values and continues.
Future<void> _fillDetails(WidgetTester tester, AppLocalizations l10n,
    {IdentityDocumentType type = IdentityDocumentType.passport, String? number}) async {
  expect(find.text(l10n.identityDetailsTitle), findsOneWidget);
  await tester.tap(find.byKey(ValueKey('idv-type-${type.wireValue}')));
  await tester.pumpAndSettle();
  number ??= switch (type) {
    IdentityDocumentType.egyptianNationalId => '٢٩٠٠١١٥٠١١٢٣٥٧',
    IdentityDocumentType.saudiNationalId => '1098765432',
    IdentityDocumentType.saudiIqama => '2098765432',
    IdentityDocumentType.passport => 'L898902C3',
  };
  await tester.enterText(
      find.descendant(of: find.byKey(const ValueKey('idv-name')), matching: find.byType(TextField)),
      'Anna Maria Eriksson');
  await tester.enterText(
      find.descendant(of: find.byKey(const ValueKey('idv-number')), matching: find.byType(TextField)),
      number);
  if (!type.birthDateInNumber) {
    await tester.tap(find.byKey(const ValueKey('idv-dob')));
    await tester.pumpAndSettle();
    final String ok = MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog))).okButtonLabel;
    await tester.tap(find.text(ok));
    await tester.pumpAndSettle();
  } else {
    expect(find.byKey(const ValueKey('idv-dob')), findsNothing);
    expect(find.text(l10n.identityBirthDateFromNumber), findsOneWidget);
  }
  await _continueDetails(tester);
}

Future<void> _continueDetails(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('idv-details-continue')));
  await tester.pumpAndSettle();
}

Future<void> _submitDocumentAndSelfie(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await _dismissIntro(tester, l10n);
  await _captureAndSubmitDocument(tester, l10n);
  await _captureSelfie(tester);
}

void main() {
  testWidgets('document → selfie → processing → verified → reservation (EN)',
      (WidgetTester tester) async {
    final en = await _l10n('en');
    final id = reservationIdForScenario(DummyVerificationScenario.autoApprove);
    await _open(tester, id);

    expect(find.text(en.identityIntroBannerTitle), findsOneWidget);
    await _submitDocumentAndSelfie(tester, en);

    expect(find.text(en.identityApprovedTitle), findsOneWidget);
    await tester.tap(
      find.widgetWithText(OutlinedButton, en.identityBackToReservation),
    );
    await tester.pumpAndSettle();
    expect(find.text(en.bookingDetailTitle), findsWidgets);
  });

  testWidgets('the ID uses the rear camera and the selfie the front one',
      (WidgetTester tester) async {
    final en = await _l10n('en');
    final FakeIdentityCamera camera = FakeIdentityCamera();
    await _open(
      tester,
      reservationIdForScenario(DummyVerificationScenario.autoApprove),
      camera: camera,
    );
    await _submitDocumentAndSelfie(tester, en);
    expect(camera.captures, <IdentityCaptureTarget>[
      IdentityCaptureTarget.document,
      IdentityCaptureTarget.selfie,
    ]);
  });

  testWidgets('closing the camera without a photo stays on the capture step',
      (WidgetTester tester) async {
    final en = await _l10n('en');
    final FakeIdentityCamera camera =
        FakeIdentityCamera(result: const IdentityCaptureCancelled());
    await _open(
      tester,
      reservationIdForScenario(DummyVerificationScenario.autoApprove),
      camera: camera,
    );
    await _dismissIntro(tester, en);
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();

    expect(find.text(en.identityCaptureDocumentTitle), findsOneWidget);
    expect(find.text(en.identityReviewDocumentTitle), findsNothing);
  });

  testWidgets('a denied camera permission shows the open-settings screen',
      (WidgetTester tester) async {
    final en = await _l10n('en');
    final FakeIdentityCamera camera = FakeIdentityCamera(
      result: const IdentityCameraUnavailable(permissionDenied: true),
    );
    await _open(
      tester,
      reservationIdForScenario(DummyVerificationScenario.autoApprove),
      camera: camera,
    );
    await _dismissIntro(tester, en);
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();

    expect(find.text(en.identityCameraDeniedTitle), findsOneWidget);
    expect(find.widgetWithText(FilledButton, en.identityOpenSettingsCta), findsOneWidget);

    // "Back" returns to the capture screen.
    await tester.tap(find.widgetWithText(OutlinedButton, en.commonBack));
    await tester.pumpAndSettle();
    expect(find.text(en.identityCaptureDocumentTitle), findsOneWidget);
  });

  testWidgets('manual-review scenario shows the safe waiting state',
      (tester) async {
    final en = await _l10n('en');
    final id = reservationIdForScenario(DummyVerificationScenario.manualReview);
    await _open(tester, id);
    await _submitDocumentAndSelfie(tester, en);
    expect(find.text(en.identityManualReviewTitle), findsOneWidget);
  });

  testWidgets('retry scenario (face not matched) shows a retry CTA and recovers',
      (tester) async {
    final en = await _l10n('en');
    final id =
        reservationIdForScenario(DummyVerificationScenario.retryThenApprove);
    await _open(tester, id);
    await _submitDocumentAndSelfie(tester, en);

    // Back on a retry-eligible failure screen — no intro shown again.
    expect(find.text(en.identityFaceNotMatchedBannerTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.identityRetryCta));
    await tester.pumpAndSettle();

    // The details are kept from the first attempt — just confirm them.
    await _continueDetails(tester);
    await _captureAndSubmitDocument(tester, en);
    await _captureSelfie(tester);
    expect(find.text(en.identityApprovedTitle), findsOneWidget);
  });

  testWidgets(
      'retry scenario (document unclear) shows the distinct failure screen',
      (tester) async {
    final en = await _l10n('en');
    final id = reservationIdForScenario(
      DummyVerificationScenario.retryUnclearThenApprove,
    );
    await _open(tester, id);
    await _submitDocumentAndSelfie(tester, en);

    expect(find.text(en.identityDocumentUnclearBannerTitle), findsOneWidget);
    // Never confused with the face-mismatch copy.
    expect(find.text(en.identityFaceNotMatchedBannerTitle), findsNothing);
  });

  testWidgets('rejected scenario shows a safe rejection with retry',
      (tester) async {
    final en = await _l10n('en');
    final id =
        reservationIdForScenario(DummyVerificationScenario.rejectThenReview);
    await _open(tester, id);
    await _submitDocumentAndSelfie(tester, en);
    expect(find.text(en.identityRejectedTitle), findsWidgets);
    // No provider/internal detail leaked.
    expect(find.textContaining('score'), findsNothing);
  });

  testWidgets('the flow renders right-to-left in Arabic', (tester) async {
    final ar = await _l10n('ar');
    final id = reservationIdForScenario(DummyVerificationScenario.autoApprove);
    await _open(tester, id, locale: arabic);

    expect(
      Directionality.of(
          tester.element(find.text(ar.identityIntroBannerTitle))),
      TextDirection.rtl,
    );
    await _submitDocumentAndSelfie(tester, ar);
    expect(find.text(ar.identityApprovedTitle), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text(ar.identityApprovedTitle))),
      TextDirection.rtl,
    );
  });

  testWidgets('the details form requires name, number and date of birth',
      (tester) async {
    final en = await _l10n('en');
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove));
    await tester.tap(find.widgetWithText(FilledButton, en.identityIntroCta));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.descendant(of: find.byKey(const ValueKey('idv-name')), matching: find.byType(TextField)), '');
    await _continueDetails(tester);

    expect(find.text(en.identityDetailsTitle), findsOneWidget);
    expect(find.text(en.identityFieldRequired), findsWidgets);
    expect(find.text(en.identityCaptureDocumentTitle), findsNothing);
  });

  testWidgets('a details mismatch explains what to check; editing re-uploads the kept photo',
      (tester) async {
    final en = await _l10n('en');
    final source = DummyIdentityVerificationDataSource()
      ..nextDocumentCheck = DocumentCheckStatus.mismatch;
    final FakeIdentityCamera camera = FakeIdentityCamera();
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove),
        source: source, camera: camera);
    await _dismissIntro(tester, en);
    await _captureAndSubmitDocument(tester, en);

    expect(find.text(en.identityMismatchTitle), findsOneWidget);
    expect(find.text(en.identityMismatchFieldsBody(en.identityFieldDocumentNumber)), findsOneWidget);
    expect(find.text(en.identityCaptureSelfieHint), findsNothing, reason: 'no selfie while rejected');

    await tester.tap(find.widgetWithText(FilledButton, en.identityEditDetailsCta));
    await tester.pumpAndSettle();
    // The contradicted field is flagged on the form.
    expect(find.text(en.identityMismatchTitle), findsOneWidget);
    await _continueDetails(tester);

    // Photo kept → straight to review, no second camera capture.
    expect(find.text(en.identityReviewDocumentTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.identityReviewContinueCta));
    await tester.pumpAndSettle();
    expect(find.text(en.identityDocumentAcceptedTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.identityReviewContinueCta));
    await tester.pumpAndSettle();
    await _captureSelfie(tester);

    expect(find.text(en.identityApprovedTitle), findsOneWidget);
    expect(camera.captures, <IdentityCaptureTarget>[
      IdentityCaptureTarget.document,
      IdentityCaptureTarget.selfie,
    ]);
  });

  testWidgets('an expired document asks for another document', (tester) async {
    final en = await _l10n('en');
    final source = DummyIdentityVerificationDataSource()
      ..nextDocumentCheck = DocumentCheckStatus.documentExpired;
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove), source: source);
    await _dismissIntro(tester, en);
    await _captureAndSubmitDocument(tester, en);

    expect(find.text(en.identityExpiredTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.identityUseAnotherDocumentCta));
    await tester.pumpAndSettle();
    expect(find.text(en.identityDetailsTitle), findsOneWidget);
  });

  testWidgets('an unreadable document offers a retake', (tester) async {
    final en = await _l10n('en');
    final source = DummyIdentityVerificationDataSource()
      ..nextDocumentCheck = DocumentCheckStatus.ocrFailed;
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove), source: source);
    await _dismissIntro(tester, en);
    await _captureAndSubmitDocument(tester, en);

    expect(find.text(en.identityDocumentUnclearBannerTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.identityReviewRetakeCta));
    await tester.pumpAndSettle();
    expect(find.text(en.identityCaptureDocumentTitle), findsOneWidget);
  });

  testWidgets('an unsupported document names the accepted ones', (tester) async {
    final en = await _l10n('en');
    final source = DummyIdentityVerificationDataSource()
      ..nextDocumentCheck = DocumentCheckStatus.documentUnsupported;
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove), source: source);
    await _dismissIntro(tester, en);
    await _captureAndSubmitDocument(tester, en);

    expect(find.text(en.identityUnsupportedTitle), findsOneWidget);
    expect(find.text(en.identityUnsupportedBody), findsOneWidget);
  });

  testWidgets('Egyptian ID (Arabic, RTL): no birth-date field, front + back uploaded, accepted, verified',
      (tester) async {
    final ar = await _l10n('ar');
    final source = _RecordingSource();
    final camera = FakeIdentityCamera();
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove),
        locale: arabic, source: source, camera: camera);
    await tester.tap(find.widgetWithText(FilledButton, ar.identityIntroCta));
    await tester.pumpAndSettle();

    // The type explains which sides are needed.
    await tester.tap(find.byKey(const ValueKey('idv-type-egyptian_national_id')));
    await tester.pumpAndSettle();
    expect(find.textContaining(ar.identityDocumentSidesFrontAndBack), findsOneWidget);
    expect(Directionality.of(tester.element(find.text(ar.identityDetailsTitle))), TextDirection.rtl);

    await _fillDetails(tester, ar, type: IdentityDocumentType.egyptianNationalId);
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();
    expect(find.text(ar.identityCaptureBackTitle), findsOneWidget);
    expect(find.byKey(const ValueKey('idv-skip-back')), findsNothing, reason: 'back is required');
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();
    expect(find.text(ar.identityReviewBothSides), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, ar.identityReviewContinueCta));
    await tester.pumpAndSettle();

    expect(find.text(ar.identityDocumentAcceptedTitle), findsOneWidget);
    final req = source.requests.single;
    expect(req.type, IdentityDocumentType.egyptianNationalId);
    expect(req.backImage, isNotNull);
    expect(req.claim!.dateOfBirth, isNull);
    expect(req.claim!.toFields()['document_number'], '29001150112357', reason: 'Western digits on the wire');

    await tester.tap(find.widgetWithText(FilledButton, ar.identityReviewContinueCta));
    await tester.pumpAndSettle();
    await _captureSelfie(tester);
    expect(find.text(ar.identityApprovedTitle), findsOneWidget);
    expect(camera.captures, <IdentityCaptureTarget>[
      IdentityCaptureTarget.document,
      IdentityCaptureTarget.document,
      IdentityCaptureTarget.selfie,
    ]);
  });

  testWidgets('Saudi Iqama: the back is optional and can be skipped', (tester) async {
    final en = await _l10n('en');
    final source = _RecordingSource();
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove), source: source);
    await tester.tap(find.widgetWithText(FilledButton, en.identityIntroCta));
    await tester.pumpAndSettle();
    await _fillDetails(tester, en, type: IdentityDocumentType.saudiIqama);

    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('idv-skip-back')));
    await tester.pumpAndSettle();
    expect(find.text(en.identityReviewDocumentBody), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.identityReviewContinueCta));
    await tester.pumpAndSettle();

    expect(source.requests.single.type, IdentityDocumentType.saudiIqama);
    expect(source.requests.single.backImage, isNull);
    expect(source.requests.single.claim!.dateOfBirth, isNotNull);
  });

  testWidgets('a passport goes straight from the front photo to review', (tester) async {
    final en = await _l10n('en');
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove));
    await _dismissIntro(tester, en);
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();

    expect(find.text(en.identityCaptureBackTitle), findsNothing);
    expect(find.text(en.identityReviewDocumentTitle), findsOneWidget);
  });

  testWidgets('number format is validated per document type', (tester) async {
    final en = await _l10n('en');
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove));
    await tester.tap(find.widgetWithText(FilledButton, en.identityIntroCta));
    await tester.pumpAndSettle();

    Future<void> tryNumber(String type, String number) async {
      await tester.tap(find.byKey(ValueKey('idv-type-$type')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.descendant(of: find.byKey(const ValueKey('idv-name')), matching: find.byType(TextField)), 'Test Name');
      await tester.enterText(
          find.descendant(of: find.byKey(const ValueKey('idv-number')), matching: find.byType(TextField)), number);
      await _continueDetails(tester);
    }

    await tryNumber('egyptian_national_id', '12345678901234'); // century 1
    expect(find.text(en.identityDocumentNumberInvalidForType), findsOneWidget);
    await tryNumber('saudi_national_id', '2098765432'); // Iqama prefix
    expect(find.text(en.identityDocumentNumberInvalidForType), findsOneWidget);
    expect(find.text(en.identityCaptureDocumentTitle), findsNothing);
  });

  testWidgets('a document sent to manual review says so before the selfie', (tester) async {
    final en = await _l10n('en');
    final source = DummyIdentityVerificationDataSource()
      ..nextDocumentCheck = DocumentCheckStatus.needsReview;
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.manualReview), source: source);
    await _dismissIntro(tester, en);
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, en.identityReviewContinueCta));
    await tester.pumpAndSettle();

    expect(find.text(en.identityDocumentReviewTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, en.identityReviewContinueCta));
    await tester.pumpAndSettle();
    expect(find.text(en.identityCaptureSelfieTitle), findsOneWidget);
  });

  testWidgets('upload progress, then "reading your ID" while the server checks it', (tester) async {
    final en = await _l10n('en');
    final source = _GatedSource();
    await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove), source: source);
    await _dismissIntro(tester, en);
    await tester.tap(find.byKey(_shutterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, en.identityReviewContinueCta));
    await tester.pump();

    expect(find.text(en.identityUploadingBannerTitle), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(find.byKey(const ValueKey('idv-upload-progress')));
    expect(bar.value, 0.4);

    source.sent.complete();
    await tester.pump();
    expect(find.text(en.identityReadingDocumentTitle), findsOneWidget);

    source.read.complete();
    await tester.pumpAndSettle();
    expect(find.text(en.identityDocumentAcceptedTitle), findsOneWidget);
  });

  for (final (String name, Object error, bool uploadScreen) in <(String, Object, bool)>[
    ('timeout', const RequestTimeoutException(), true),
    ('401', const UnauthorizedException(), false),
    ('403', const ForbiddenException(), false),
    ('422', const ValidationException(<String, List<String>>{'document_number': <String>['invalid']}), false),
    ('500', const ServerException(), false),
  ]) {
    testWidgets('a $name on upload shows an actionable failure, never a silent stall', (tester) async {
      final en = await _l10n('en');
      final source = DummyIdentityVerificationDataSource();
      await _open(tester, reservationIdForScenario(DummyVerificationScenario.autoApprove), source: source);
      await _dismissIntro(tester, en);
      await tester.tap(find.byKey(_shutterButton));
      await tester.pumpAndSettle();
      source.failWith = error;
      await tester.tap(find.widgetWithText(FilledButton, en.identityReviewContinueCta));
      await tester.pumpAndSettle();

      if (uploadScreen) {
        expect(find.text(en.identityFailedUploadBannerTitle), findsOneWidget);
        return;
      }
      expect(find.text(en.identitySubmitFailedTitle), findsOneWidget);
      if (error is ValidationException) {
        // 422 → back to the details form to fix them.
        source.failWith = null;
        await tester.tap(find.widgetWithText(FilledButton, en.identityEditDetailsCta));
        await tester.pumpAndSettle();
        expect(find.text(en.identityDetailsTitle), findsOneWidget);
      } else {
        expect(find.widgetWithText(FilledButton, en.actionRetry), findsOneWidget);
      }
    });
  }
}
