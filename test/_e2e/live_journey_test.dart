// LIVE end-to-end journey (30 steps) through the app's real API data sources
// against a running backend (localhost:8000), cross-checked against the
// dashboard's staff API and the backend database. Skipped unless LIVE_API=1.
//
//   LIVE_API=1 flutter test test/_e2e/live_journey_test.dart \
//     --dart-define=SCRATCH=<dir with id.jpg + selfie.jpg>
//
// Needs the local dev stack: `php artisan serve` on :8000, MySQL
// `hotel_platform` reachable as root, the seeded staff users
// (Password123!) and hotel 4 / room types 7–8. Every configuration the test
// changes is restored in tearDown, and the test's own guest, reservations
// and identity files are removed afterwards.
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_guest_app/core/network/api_client.dart';
import 'package:hotel_guest_app/core/network/interceptors/auth_interceptor.dart';
import 'package:hotel_guest_app/core/network/interceptors/error_interceptor.dart';
import 'package:hotel_guest_app/core/security/in_memory_token_store.dart';
import 'package:hotel_guest_app/features/authentication/data/datasources/api_auth_data_source.dart';
import 'package:hotel_guest_app/features/authentication/data/models/auth_models.dart';
import 'package:hotel_guest_app/features/checkout/data/datasources/api_checkout_data_source.dart';
import 'package:hotel_guest_app/features/checkout/domain/entities/checkout.dart';
import 'package:hotel_guest_app/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:hotel_guest_app/features/digital_access/data/datasources/api_digital_access_data_source.dart';
import 'package:hotel_guest_app/features/digital_access/domain/entities/check_in.dart';
import 'package:hotel_guest_app/features/discovery/data/datasources/api_discovery_data_source.dart';
import 'package:hotel_guest_app/features/discovery/data/datasources/favorites/favorite_hotels_data_source.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/guest_party.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/localized_text.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/money.dart';
import 'package:hotel_guest_app/features/discovery/domain/entities/stay_range.dart';
import 'package:hotel_guest_app/features/identity_verification/data/datasources/api_identity_verification_data_source.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_document.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_verification_request.dart';
import 'package:hotel_guest_app/features/loyalty/data/datasources/api_loyalty_data_source.dart';
import 'package:hotel_guest_app/features/loyalty/domain/entities/loyalty_operations.dart';
import 'package:hotel_guest_app/features/notifications/data/datasources/api_notifications_data_source.dart';
import 'package:hotel_guest_app/features/payment/data/datasources/api_payment_data_source.dart';
import 'package:hotel_guest_app/features/payment/domain/entities/payment_request.dart';
import 'package:hotel_guest_app/features/profile/data/datasources/api_profile_data_source.dart';
import 'package:hotel_guest_app/features/reservation/data/datasources/api_reservation_data_source.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/create_reservation_request.dart';
import 'package:hotel_guest_app/features/reservation/domain/entities/reservation_status.dart';
import 'package:hotel_guest_app/features/stay_services/data/datasources/api_stay_services_data_source.dart';
import 'package:hotel_guest_app/features/stay_services/domain/entities/service_order.dart';

const String base = 'http://127.0.0.1:8000/api/v1';
const String scratch = String.fromEnvironment('SCRATCH');
const String backendDir = '../backend';
const String hotelId = '4';
const int roomTypeId = 7;
const int nonRefundableTypeId = 8;

void log(String s) => stdout.writeln('E2E ▸ $s');

/// One scalar from the dev database (the backend's source of truth).
Future<String> db(String sql) async {
  final ProcessResult r = await Process.run(
      'mysql', <String>['-uroot', 'hotel_platform', '-N', '-B', '-e', sql]);
  if (r.exitCode != 0) throw StateError('mysql: ${r.stderr}');
  return (r.stdout as String).trim();
}

Future<String> artisan(List<String> args) async {
  final ProcessResult r = await Process.run('php', <String>['artisan', ...args],
      workingDirectory: backendDir);
  if (r.exitCode != 0) throw StateError('artisan: ${r.stderr}${r.stdout}');
  return (r.stdout as String).trim();
}

bool storedFileExists(String relative) =>
    File('$backendDir/storage/app/private/$relative').existsSync();

Future<Dio> staffLogin(String email) async {
  final Dio d = Dio(BaseOptions(
    baseUrl: base,
    headers: <String, String>{'Accept': 'application/json'},
    validateStatus: (_) => true,
  ));
  final Response<dynamic> login = await d.post<dynamic>('/auth/login',
      data: <String, String>{'email': email, 'password': 'Password123!'});
  expect(login.statusCode, 200, reason: 'staff login $email');
  d.options.headers['Authorization'] = 'Bearer ${login.data['data']['token']}';
  return d;
}

Future<Map<String, dynamic>> ok(Future<Response<dynamic>> call, [int status = 200]) async {
  final Response<dynamic> r = await call;
  expect(r.statusCode, status, reason: '${r.requestOptions.method} ${r.requestOptions.path} → ${r.data}');
  return (r.data as Map<String, dynamic>?) ?? <String, dynamic>{};
}

DateTime day(int offset) {
  final DateTime n = DateTime.now().add(Duration(days: offset));
  return DateTime(n.year, n.month, n.day);
}

void main() {
  final bool live = Platform.environment['LIVE_API'] == '1';

  test('30-step guest journey: dashboard config → mobile → backend → dashboard', () async {
    HttpOverrides.global = null;
    final Dio owner = await staffLogin('owner@hotel.test');

    // Snapshot everything the journey reconfigures; restored in tearDown.
    final Map<String, dynamic> hotelBefore = (await ok(owner.get<dynamic>('/hotels/$hotelId')))['data'] as Map<String, dynamic>;
    final String groupId = '${hotelBefore['hotel_group_id'] ?? await db('select hotel_group_id from hotels where id=$hotelId')}';
    final String priceBefore = await db('select base_price from room_types where id=$roomTypeId');
    final bool refundableBefore = await db('select refundable from room_types where id=$roomTypeId') == '1';
    final Map<String, dynamic> loyaltyBefore = (await ok(owner.get<dynamic>('/hotel-groups/$groupId/loyalty-rule')))['data'] as Map<String, dynamic>;
    final String checkInTimeBefore = (await db('select check_in_time from hotels where id=$hotelId')).substring(0, 5);
    final List<String> reservationIds = <String>[];
    String? guestId;
    addTearDown(() async {
      await owner.patch<dynamic>('/hotels/$hotelId', data: <String, Object?>{
        'deposit_percentage': hotelBefore['deposit_percentage'],
        'check_in_mode': hotelBefore['check_in_mode'] ?? 'both',
        'check_in_time': checkInTimeBefore,
        'service_fee_enabled': hotelBefore['service_fee_enabled'] ?? false,
        'service_fee_type': hotelBefore['service_fee_type'],
        'service_fee_value': hotelBefore['service_fee_value'],
      });
      await owner.patch<dynamic>('/hotels/$hotelId/room-types/$roomTypeId', data: <String, Object?>{'base_price': priceBefore, 'refundable': refundableBefore});
      await owner.patch<dynamic>('/hotels/$hotelId/room-types/$nonRefundableTypeId', data: <String, Object?>{'refundable': true});
      await owner.put<dynamic>('/hotel-groups/$groupId/loyalty-rule', data: <String, Object?>{
        'is_active': loyaltyBefore['is_active'] ?? false,
        'earn_points_per_currency': loyaltyBefore['earn_points_per_currency'] ?? 0,
        'redeem_currency_per_point': loyaltyBefore['redeem_currency_per_point'] ?? 0,
        'max_redeem_points': loyaltyBefore['max_redeem_points'] ?? 0,
      });
      final String restored = await db('select concat(is_active,"/",earn_points_per_currency,"/",redeem_currency_per_point,"/",max_redeem_points) from loyalty_rules where hotel_group_id=$groupId');
      log('teardown: hotel $hotelId, room types, loyalty ($restored) restored');
      if (guestId != null) {
        final ProcessResult r = await Process.run('php', <String>['artisan', 'tinker', '--execute', _cleanupPhp(guestId, reservationIds)], workingDirectory: backendDir);
        log('teardown: removed E2E guest #$guestId + ${reservationIds.length} reservations ${r.exitCode == 0 ? '' : '(cleanup failed: ${r.stderr})'}');
      }
    });

    // ── Dashboard configuration (staff API the dashboard calls) ──────────
    // 1. Hotel configuration.
    await ok(owner.patch<dynamic>('/hotels/$hotelId', data: <String, Object?>{'check_in_time': '14:00'}));
    // 2. Deposit — deliberately not the launch 20% to prove nothing is hardcoded.
    await ok(owner.patch<dynamic>('/hotels/$hotelId', data: <String, Object?>{'deposit_percentage': 25}));
    // Service fee switched on from the dashboard: fixed 30 per booking.
    await ok(owner.patch<dynamic>('/hotels/$hotelId', data: <String, Object?>{
      'service_fee_enabled': true, 'service_fee_type': 'fixed', 'service_fee_value': 30,
    }));
    // 3. Check-in configuration.
    await ok(owner.patch<dynamic>('/hotels/$hotelId', data: <String, Object?>{'check_in_mode': 'both'}));
    expect(await db('select concat(deposit_percentage,"|",check_in_mode,"|",check_in_time) from hotels where id=$hotelId'), '25.00|both|14:00:00');
    // 4. Cancellation configuration (non-refundable rate).
    await ok(owner.patch<dynamic>('/hotels/$hotelId/room-types/$nonRefundableTypeId', data: <String, Object?>{'refundable': false}));
    // 5. Loyalty configuration (launch state is disabled/zero; enabled here).
    await ok(owner.put<dynamic>('/hotel-groups/$groupId/loyalty-rule', data: <String, Object?>{
      'is_active': true, 'earn_points_per_currency': 1, 'redeem_currency_per_point': 1, 'max_redeem_points': 5000,
    }));
    // 6. Room / rate configuration — halalas on purpose.
    await ok(owner.patch<dynamic>('/hotels/$hotelId/room-types/$roomTypeId', data: <String, Object?>{'base_price': '246.50', 'refundable': true}));
    log('1–6 dashboard config: check-in 14:00, deposit 25%, mode both, type $nonRefundableTypeId non-refundable, loyalty on, rate 246.50');

    // ── Guest app ────────────────────────────────────────────────────────
    final InMemoryTokenStore tokens = InMemoryTokenStore();
    final ApiClient api = ApiClient.withDio(
      Dio(BaseOptions(baseUrl: base, headers: <String, String>{'X-Locale': 'ar'}))
        ..interceptors.addAll(<Interceptor>[AuthInterceptor(tokens), ErrorInterceptor()]),
    );

    // 7. Mobile hotel retrieval reflects the dashboard config.
    final ApiDiscoveryDataSource discovery = ApiDiscoveryDataSource(api);
    final hotel = await discovery.fetchHotel(hotelId);
    expect(hotel.details.checkInTime, '14:00');
    log('7 app hotel: check-in ${hotel.details.checkInTime}');

    // 8. Guest login (OTP) + profile.
    final ApiAuthDataSource auth = ApiAuthDataSource(api);
    final String phone = '+9665${(10000000 + Random().nextInt(89999999))}';
    final OtpChallengeModel challenge = await auth.requestOtp(phone);
    final OtpVerifyResult verified = await auth.verifyOtp(
        challengeId: challenge.challengeId, phoneE164: phone, attemptsRemaining: 3, code: '123456');
    final AuthSessionModel session = (verified as OtpVerifyAccepted).session;
    await tokens.writeAccessToken(session.accessToken);
    await auth.completeProfile(
        accessToken: session.accessToken, phoneE164: phone, fullName: 'App E2E Guest', email: 'app.e2e@example.test');
    guestId = await db("select id from guests where phone='$phone'");
    log('8 guest #$guestId signed in via OTP');

    // 9. Room selection — availability shows the configured rate + currency.
    final StayRange stay = StayRange(checkIn: day(2), checkOut: day(4));
    final availability = await discovery.fetchAvailability(
        hotelId: hotelId, checkIn: stay.checkIn, checkOut: stay.checkOut, adults: 2, children: 0);
    final room = availability.rooms.firstWhere((r) => r.roomType.id == '$roomTypeId');
    expect(room.isAvailable, isTrue);
    expect(room.roomType.nightlyRate.amount, 246.5);
    expect(room.roomType.nightlyRate.currency, 'SAR');
    log('9 room $roomTypeId available at ${room.roomType.nightlyRate.amount} ${room.roomType.nightlyRate.currency}');

    // 10. Booking creation.
    final ApiReservationDataSource reservations = ApiReservationDataSource(api);
    final r = await reservations.create(CreateReservationRequest(
      hotelId: hotelId,
      hotelName: const LocalizedText(ar: 'فندق الواحة', en: 'Al Waha'),
      roomTypeId: '$roomTypeId',
      roomName: const LocalizedText(ar: 'غرفة ديلوكس', en: 'Deluxe'),
      stay: stay,
      party: const GuestParty(adults: 2, children: 0),
      guestReference: 'app-e2e',
      priceSnapshot: const Money(amount: 1), // the server prices it, not the app
    ));
    final String id = r.id;
    reservationIds.add(id);

    // 11. Backend price calculation (nights × configured rate).
    expect(r.priceSnapshot.amount, 493);
    expect(await db('select price_snapshot from reservations where id=$id'), '493.00');
    // 12. Currency snapshot.
    expect(r.priceSnapshot.currency, 'SAR');
    expect(await db('select currency from reservations where id=$id'), 'SAR');
    expect(r.hotelCheckInTime, '14:00');
    // The hotel's service fee is snapshotted on the booking.
    expect(r.serviceFee?.amount, 30);
    expect(r.toEntity().totalToPay.amount, 523);
    expect(await db('select service_fee_amount from reservations where id=$id'), '30.00');
    final Map<String, dynamic> dash1 = (await ok(owner.get<dynamic>('/reservations/$id')))['data'] as Map<String, dynamic>;
    expect(dash1['status'], 'pending');
    log('10–12 reservation #$id: 493.00 SAR computed server-side; dashboard sees pending');

    // 13–15. Deposit = 25% of the stay, halalas kept → CONFIRMED (deposit_held).
    final payment = await ApiPaymentDataSource(api).requestHold(
        PaymentHoldRequest(reservationId: id, amount: const Money(amount: 0)));
    expect(payment.amount, 123.25);
    expect(await db('select concat(amount,"|",currency,"|",status) from payments where reservation_id=$id'), '123.25|SAR|hold_active');
    expect(await db('select pt.currency from payment_transactions pt join payments p on p.id=pt.payment_id where p.reservation_id=$id order by pt.id desc limit 1'), 'SAR');
    expect((await reservations.fetchById(id)).status, ReservationStatus.depositHeld);
    expect(((await ok(owner.get<dynamic>('/reservations/$id')))['data'] as Map)['status'], 'deposit_held');
    log('13–15 deposit 123.25 SAR held (25% of 493) → confirmed in app, DB and dashboard');

    // 16. Payment never starts the stay.
    final afterPay = await reservations.fetchById(id);
    expect(afterPay.status, isNot(ReservationStatus.inStay));
    expect(afterPay.status, isNot(ReservationStatus.checkedIn));
    final preKey = await ApiDigitalAccessDataSource(api).fetchGrant(id);
    expect(preKey?.status.wireValue, isNot('active'));
    expect(await db("select count(*) from access_grants where reservation_id=$id and status='active'"), '0');
    log('16 payment confirmed only — no check-in, key status ${preKey?.status.wireValue}');

    // 17. Identity verification with real files: upload → server-side OCR
    //     document check → comparison with the guest's typed details →
    //     selfie → staff approves. The local backend runs the dummy OCR
    //     provider (synthetic ICAO "Utopia" specimen passport — production
    //     refuses it); the claim below is that SYNTHETIC identity.
    final ApiIdentityVerificationDataSource idv = ApiIdentityVerificationDataSource(api);
    CapturedImage file(String name) =>
        CapturedImage(label: name, sizeBytes: File('$scratch/$name').lengthSync(), filePath: '$scratch/$name');
    IdentityDocumentClaim claim(String number) =>
        IdentityDocumentClaim(fullName: 'Anna Maria Eriksson', documentNumber: number, dateOfBirth: DateTime(1974, 8, 12));

    // 17-pre. Document-type catalog + an Egyptian National ID (front + back,
    //         synthetic specimen, Arabic name + Arabic-Indic digits, no DOB).
    //         Custom-model types always go to manual review until their model
    //         is evaluated, so this ends NEEDS_REVIEW — then the guest
    //         switches to the passport below (same attempt, replaced).
    final options = await idv.documentTypes();
    expect(options.map((o) => o.type).toList(), <IdentityDocumentType>[
      IdentityDocumentType.egyptianNationalId,
      IdentityDocumentType.saudiNationalId,
      IdentityDocumentType.saudiIqama,
      IdentityDocumentType.passport,
    ]);
    expect(options.first.back, BackImagePolicy.required);
    final egypt = (await idv.submitDocument(SubmitIdentityDocumentRequest(
      reservationId: id,
      type: IdentityDocumentType.egyptianNationalId,
      image: file('id.jpg'),
      backImage: file('id_back.jpg'),
      claim: const IdentityDocumentClaim(fullName: 'سامي عادل فؤاد منصور', documentNumber: '٢٩٠٠١١٥٠١١٢٣٥٧'),
    ))).toEntity();
    expect(egypt.documentCheck!.status.wireValue, 'needs_review');
    expect(egypt.documentCheck!.reasons, <String>['manual_review_required_for_document_type']);
    expect(await db('select concat(document_type,"|",document_back_path like "%-document_back-%.enc") from identity_verification_attempts a join identity_verification_sessions s on s.id=a.session_id where s.reservation_id=$id'),
        'egyptian_national_id|1');
    log('17-pre catalog: 4 types (Egypt back required); Egyptian ID front+back → needs_review (manual review by policy), back image encrypted');

    // 17a. Failure path: a wrong document number is a MISMATCH — the rejected
    //      document is deleted at once and the selfie step stays closed.
    final List<double> progress = <double>[];
    final mismatch = (await idv.submitDocument(
      SubmitIdentityDocumentRequest(reservationId: id, type: IdentityDocumentType.passport, image: file('id.jpg'), claim: claim('X0000000')),
      onProgress: progress.add,
    )).toEntity();
    expect(progress.last, 1.0, reason: 'upload progress reported');
    expect(mismatch.documentCheck!.status.wireValue, 'mismatch');
    expect(mismatch.documentCheck!.mismatchedFields, <String>['number']);
    expect(mismatch.needsSelfie, isFalse);
    expect(await db('select document_path is null from identity_verification_attempts a join identity_verification_sessions s on s.id=a.session_id where s.reservation_id=$id'), '1');
    await expectLater(
      idv.submitSelfie(SubmitSelfieRequest(reservationId: id, image: file('selfie.jpg'))),
      throwsA(anything),
      reason: 'no selfie while the document check blocks it',
    );

    // 17b. Corrected details → VERIFIED document check → selfie → review.
    final docVerified = (await idv.submitDocument(SubmitIdentityDocumentRequest(
      reservationId: id, type: IdentityDocumentType.passport, image: file('id.jpg'), claim: claim('L898902C3'),
    ))).toEntity();
    expect(docVerified.documentCheck!.status.wireValue, 'verified');
    expect(docVerified.needsSelfie, isTrue);
    await idv.submitSelfie(SubmitSelfieRequest(reservationId: id, image: file('selfie.jpg')));
    await ok(owner.post<dynamic>('/identity-verification/$id/review', data: <String, String>{'decision': 'approve'}));
    expect((await idv.fetchStatus(id)).status.wireValue, 'staff_approved');
    expect((await reservations.fetchById(id)).status, ReservationStatus.verified);
    final List<String> idFiles = (await db(
            'select concat(a.document_path,"\\n",a.selfie_path) from identity_verification_attempts a join identity_verification_sessions s on s.id=a.session_id where s.reservation_id=$id order by a.id desc limit 1'))
        .split(r'\n');
    expect(idFiles.every(storedFileExists), isTrue, reason: 'uploaded ID files on disk: $idFiles');
    expect(idFiles.every((String f) => f.endsWith('.enc')), isTrue, reason: 'encrypted at rest');
    expect(await db('select document_check_status from identity_verification_attempts a join identity_verification_sessions s on s.id=a.session_id where s.reservation_id=$id'), 'verified');
    expect(int.parse(await db("select count(*) from identity_verification_attempts a join identity_verification_sessions s on s.id=a.session_id where s.reservation_id=$id and (a.document_check like '%L898902C3%' or a.document_check like '%1974%' or a.document_check like '%ERIKSSON%')")), 0,
        reason: 'no extracted or typed identity value is stored');
    log('17 identity: mismatch rejected (doc deleted, selfie blocked) → corrected → OCR verified → selfie → staff approved → verified; files encrypted');

    // 19. Permission enforcement (before the real assignment).
    final List<dynamic> assignable = (await ok(owner.get<dynamic>('/reservations/$id/assignable-rooms')))['data'] as List<dynamic>;
    final int roomId = assignable.first['id'] as int;
    final Dio manager = await staffLogin('manager@hotel.test');
    expect((await manager.post<dynamic>('/reservations/$id/room', data: <String, int>{'room_id': roomId})).statusCode, 403,
        reason: 'reservations.manage alone must not assign rooms');
    final Dio receptionOtherHotel = await staffLogin('reception.cairo@hotel.test');
    expect((await receptionOtherHotel.post<dynamic>('/reservations/$id/room', data: <String, int>{'room_id': roomId})).statusCode, anyOf(403, 404),
        reason: 'reception outside the hotel scope (hidden as 404 by design)');
    final Dio asGuest = Dio(BaseOptions(baseUrl: base, validateStatus: (_) => true,
        headers: <String, String>{'Accept': 'application/json', 'Authorization': 'Bearer ${session.accessToken}'}));
    expect((await asGuest.post<dynamic>('/reservations/$id/room', data: <String, int>{'room_id': roomId})).statusCode, anyOf(401, 403));
    expect(await db('select room_id is null from reservations where id=$id'), '1');
    log('19 room assignment denied for manager (no reservations.assign-room), out-of-scope reception, and the guest');

    // 18. Room assignment (dedicated permission) — validated, audited.
    await ok(owner.post<dynamic>('/reservations/$id/room', data: <String, int>{'room_id': roomId}));
    expect(await db('select concat(room_id,"|",room_assigned_by_user_id is not null,"|",room_assigned_at is not null) from reservations where id=$id'), '$roomId|1|1');
    expect(int.parse(await db("select count(*) from audit_logs where action='reservation.room_assigned' and auditable_id=$id")), greaterThan(0));
    log('18 owner assigned room #$roomId (assigned_by + audit recorded)');

    // 20–22. Guest self check-in → IN_STAY → active digital key.
    final grant = await ApiDigitalAccessDataSource(api).checkIn(CheckInRequest(reservationId: id));
    expect(grant.status.wireValue, 'active');
    final inStay = await reservations.fetchById(id);
    expect(inStay.status, ReservationStatus.inStay);
    expect(inStay.roomNumber, isNotNull);
    expect(await db('select status from reservations where id=$id'), 'in_stay');
    expect(((await ok(owner.get<dynamic>('/reservations/$id')))['data'] as Map)['status'], 'in_stay');
    expect((await ApiDigitalAccessDataSource(api).fetchGrant(id))!.status.wireValue, 'active');
    log('20–22 checked in → in_stay (app/DB/dashboard agree), key active for room ${inStay.roomNumber}');

    // 23–25. Service request → staff confirms in the dashboard → app sees it.
    final ApiStayServicesDataSource services = ApiStayServicesDataSource(api);
    final catalogue = await services.fetchCatalogue(hotelId);
    final String serviceId = catalogue.services.firstWhere((s) => s.price.amount > 0).id;
    final order = await services.createOrder(CreateServiceRequest(
        reservationId: id, serviceId: serviceId, serviceName: const LocalizedText(ar: '', en: ''), quantity: 1));
    await ok(owner.post<dynamic>('/reservations/$id/service-orders/${order.id}/transition',
        data: <String, String>{'target_status': 'confirmed'}));
    expect((await services.fetchOrder(id, order.id)).status.wireValue, 'confirmed');
    expect(await db('select status from service_orders where id=${order.id}'), 'confirmed');
    log('23–25 service order #${order.id} requested in app → confirmed by staff → app shows confirmed');

    // 26. Checkout + invoice.
    final ApiCheckoutDataSource checkout = ApiCheckoutDataSource(api);
    await checkout.performCheckout(
      CheckoutRequest(reservationId: id),
      FolioContext(reservationId: id, accommodationAmount: 493, currency: 'SAR'),
    );
    final invoice = await checkout.fetchInvoice(id);
    expect((await reservations.fetchById(id)).status, ReservationStatus.invoiced);
    expect(await db("select concat(total_amount,'|',status) from folio_charges where source_type='service_fee' and source_id=$id"), '30.00|posted');
    expect(((await ok(owner.get<dynamic>('/reservations/$id')))['data'] as Map)['status'], 'invoiced');
    log('26 checked out → invoice ${invoice.invoiceNumber} (${invoice.subtotal.amount} ${invoice.subtotal.currency})');

    // 27. Loyalty reward after the completed stay — exactly once.
    final ApiLoyaltyDataSource loyalty = ApiLoyaltyDataSource(api);
    final LoyaltyContext ctx1 = LoyaltyContext(
        reservationId: id, reservationStatus: ReservationStatus.invoiced, reservationAmount: 493, currency: 'SAR');
    final int earned = (await loyalty.fetchAccount(ctx1)).pointsBalance;
    expect(earned, greaterThan(0));
    expect(await db("select count(*) from loyalty_transactions where type='earn' and source_id=$id"), '1');
    await owner.post<dynamic>('/reservations/$id/loyalty/earn'); // replay must not double-credit
    expect(await db("select count(*) from loyalty_transactions where type='earn' and source_id=$id"), '1');
    final Map<String, dynamic> dashLoyalty = (await ok(owner.get<dynamic>('/guests/$guestId/loyalty')))['data'] as Map<String, dynamic>;
    expect(dashLoyalty['points_balance'], earned);
    log('27 loyalty: $earned points credited on completion, once (app/DB/dashboard agree)');

    // Cancellation + redemption rules on a second booking.
    final r2 = await reservations.create(CreateReservationRequest(
      hotelId: hotelId, hotelName: const LocalizedText(ar: '', en: ''), roomTypeId: '$roomTypeId',
      roomName: const LocalizedText(ar: '', en: ''), stay: StayRange(checkIn: day(6), checkOut: day(7)),
      party: const GuestParty(adults: 1, children: 0), guestReference: 'app-e2e-2', priceSnapshot: const Money(amount: 1)));
    reservationIds.add(r2.id);
    expect(r2.cancellation.allowed, isTrue, reason: 'cancellation: ${r2.cancellation.reason} refundable=${r2.cancellation.refundable} until=${r2.cancellation.freeUntil}');
    expect(r2.cancellation.freeUntil, isNotNull);
    final redeemed = await loyalty.redeem(RedeemPointsRequest(reservationId: r2.id, points: earned),
        LoyaltyContext(reservationId: r2.id, reservationStatus: r2.status, reservationAmount: 246.5, currency: 'SAR'));
    expect(redeemed.outcome, LoyaltyRedeemOutcome.redeemed);
    expect(redeemed.transaction!.points, -247); // only what covers the 246.50 stay
    expect(await db("select total_amount from folio_charges where source_type='loyalty_redemption' and source_id=${r2.id}"), '-246.50');
    expect((await loyalty.fetchAccount(ctx1)).pointsBalance, earned - 247);
    await reservations.cancel(r2.id);
    expect((await loyalty.fetchAccount(ctx1)).pointsBalance, earned);
    expect(await db("select status from folio_charges where source_type='loyalty_redemption' and source_id=${r2.id}"), 'cancelled');
    expect(await db('select status from reservations where id=${r2.id}'), 'cancelled');
    log('loyalty redemption capped at the stay (247 pts → 246.50), free cancellation restored all $earned points');

    final r3 = await reservations.create(CreateReservationRequest(
      hotelId: hotelId, hotelName: const LocalizedText(ar: '', en: ''), roomTypeId: '$nonRefundableTypeId',
      roomName: const LocalizedText(ar: '', en: ''), stay: StayRange(checkIn: day(8), checkOut: day(9)),
      party: const GuestParty(adults: 1, children: 0), guestReference: 'app-e2e-3', priceSnapshot: const Money(amount: 1)));
    reservationIds.add(r3.id);
    expect(r3.cancellation.refundable, isFalse);
    // The policy is the booking-time snapshot: re-opening the rate later changes nothing.
    await ok(owner.patch<dynamic>('/hotels/$hotelId/room-types/$nonRefundableTypeId', data: <String, Object?>{'refundable': true}));
    await expectLater(reservations.cancel(r3.id), throwsA(anything));
    expect(await db('select concat(status,"|",is_refundable) from reservations where id=${r3.id}'), 'pending|0');
    log('non-refundable booking #${r3.id}: cancellation refused (policy snapshotted)');

    // 28. Identity retention: default delete-after-checkout; the hotel copy
    // is purged by the scheduled job once the 30-day window passes.
    final ApiProfileDataSource profile = ApiProfileDataSource(api);
    expect((await profile.fetchSettings()).keepIdentityForFuture, isFalse);
    expect(idFiles.every(storedFileExists), isTrue, reason: 'within the 30-day window the files stay');
    await db('update reservations set updated_at = now() - interval 31 day where id=$id');
    log('28 purge job: ${await artisan(<String>['identity:purge-expired-images'])}');
    expect(idFiles.any(storedFileExists), isFalse, reason: 'the stored files themselves are deleted');
    expect(await db('select count(*) from identity_verification_attempts a join identity_verification_sessions s on s.id=a.session_id where s.reservation_id=$id and (a.document_path is not null or a.selfie_path is not null)'), '0');
    log('28 identity files deleted from disk + paths cleared after the retention window');

    // 29. Notifications, favourites, booking history.
    final feed = await ApiNotificationsDataSource(api).fetchFeed();
    expect(feed.items, isNotEmpty);
    final ApiFavoriteHotelsDataSource favs = ApiFavoriteHotelsDataSource(api);
    await favs.add(hotelId);
    expect(await favs.fetchIds(), contains(hotelId));
    expect(await db('select count(*) from guest_favorite_hotels where guest_id=$guestId and hotel_id=$hotelId'), '1');
    await favs.remove(hotelId);
    expect(await favs.fetchIds(), isNot(contains(hotelId)));
    final history = await reservations.fetchList();
    final Map<String, ReservationStatus> byId = <String, ReservationStatus>{for (final h in history) h.id: h.status};
    expect(byId[id], ReservationStatus.invoiced);
    expect(byId[r2.id], ReservationStatus.cancelled);
    expect(byId[r3.id], ReservationStatus.pending);
    log('29 notifications ${feed.items.length} (unread ${feed.unreadCount}); favourite round-trip; history has 3 bookings');

    // 30. Logout revokes the token server-side.
    final String tokensBefore = await db("select count(*) from personal_access_tokens where tokenable_id=$guestId and tokenable_type like '%Guest%'");
    await auth.revokeSession();
    await expectLater(reservations.fetchList(), throwsA(anything));
    expect(await db("select count(*) from personal_access_tokens where tokenable_id=$guestId and tokenable_type like '%Guest%'"), '0');
    log('30 logout: token revoked ($tokensBefore → 0 rows); protected API refuses the old token');
  }, skip: live ? false : 'set LIVE_API=1 with the backend on :8000', timeout: const Timeout(Duration(minutes: 5)));
}

/// Removes the journey's own guest and reservations (and every row that
/// hangs off them, children first per the FK graph) plus any identity files
/// still on disk, so the dev database is left as it was. Audit-log rows are
/// kept on purpose (append-only history).
String _cleanupPhp(String guestId, List<String> reservationIds) {
  final String ids = reservationIds.join(',');
  return '''
use Illuminate\\Support\\Facades\\DB;
use Illuminate\\Support\\Facades\\Storage;
\$ids = [$ids]; \$g = $guestId;
\$sessions = DB::table('identity_verification_sessions')->whereIn('reservation_id', \$ids)->orWhere('guest_id', \$g)->pluck('id');
foreach (DB::table('identity_verification_attempts')->whereIn('session_id', \$sessions)->get() as \$a) {
  foreach ([\$a->document_path, \$a->selfie_path] as \$p) { if (\$p) Storage::disk(config('verification.storage.disk', 'local'))->delete(\$p); }
}
DB::table('identity_verification_sessions')->whereIn('id', \$sessions)->delete();
\$orders = DB::table('service_orders')->whereIn('reservation_id', \$ids)->pluck('id');
DB::table('service_reviews')->whereIn('service_order_id', \$orders)->orWhere('guest_id', \$g)->delete();
DB::table('service_orders')->whereIn('id', \$orders)->delete();
\$payments = DB::table('payments')->whereIn('reservation_id', \$ids)->pluck('id');
DB::table('payment_transactions')->whereIn('payment_id', \$payments)->delete();
DB::table('payments')->whereIn('id', \$payments)->delete();
\$invoices = DB::table('invoices')->whereIn('reservation_id', \$ids)->pluck('id');
DB::table('invoice_items')->whereIn('invoice_id', \$invoices)->delete();
DB::table('invoices')->whereIn('id', \$invoices)->delete();
foreach (['access_grants', 'folio_charges', 'checkouts', 'reservation_extensions', 'notification_events', 'problem_reports'] as \$t) {
  DB::table(\$t)->whereIn('reservation_id', \$ids)->delete();
}
\$reviews = DB::table('reviews')->whereIn('reservation_id', \$ids)->pluck('id');
DB::table('review_category_ratings')->whereIn('review_id', \$reviews)->delete();
DB::table('reviews')->whereIn('id', \$reviews)->delete();
\$accounts = DB::table('loyalty_accounts')->where('guest_id', \$g)->pluck('id');
DB::table('loyalty_transactions')->whereIn('loyalty_account_id', \$accounts)->delete();
DB::table('loyalty_accounts')->whereIn('id', \$accounts)->delete();
DB::table('reservations')->whereIn('id', \$ids)->delete();
DB::table('personal_access_tokens')->where('tokenable_id', \$g)->where('tokenable_type', 'like', '%Guest%')->delete();
\$phone = DB::table('guests')->where('id', \$g)->value('phone');
DB::table('guest_otp_challenges')->where('phone', \$phone)->delete();
DB::table('guests')->where('id', \$g)->delete();
echo 'ok';
''';
}
