import '../../../../core/data/data_source.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../discovery/domain/entities/guest_party.dart';
import '../../../discovery/domain/entities/localized_text.dart';
import '../../../discovery/domain/entities/money.dart';
import '../../domain/entities/create_reservation_request.dart';
import '../../domain/entities/extend_stay.dart';
import '../../domain/entities/reservation_status.dart';
import '../models/reservation_models.dart';
import 'reservation_data_source.dart';

/// Deterministic, offline reservation source used while no guest-facing
/// reservation API contract is approved.
///
/// Guarantees required by the phase brief:
/// * no network, no timers, no randomness, no artificial delays;
/// * a reservation's id / reference / created-at are derived purely from the
///   request (via [CreateReservationRequest.idempotencyKey]) and the injected
///   [clock] — the same request always yields the same reservation;
/// * [create] is idempotent: a repeat of the same request returns the reservation
///   already made, it never makes a second one;
/// * a fresh reservation is `PENDING`, matching the backend state machine.
///
/// [_seedFixtures] pre-populates one reservation per status the Bookings /
/// Services screens need to render (mobile/docs/mobile-phase-11-bookings-account.md)
/// — every date is computed from [clock] so "currently staying" / "upcoming" /
/// "past" always classify correctly relative to whenever the app runs.
///
/// [failWith] is a test seam (mirrors `DummyHealthDataSource.error`) so the
/// error / recovery UI can be exercised without any real failure.
class DummyReservationDataSource
    implements ReservationDataSource, DummyDataSource {
  DummyReservationDataSource({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _seedFixtures();
  }

  final DateTime Function() _clock;
  final Map<String, ReservationModel> _byId = <String, ReservationModel>{};
  final Map<String, String> _idByKey = <String, String>{};

  /// When non-null, the next [create] / [fetchById] / [fetchList] / [cancel] /
  /// [extend] throws this instead.
  Object? failWith;

  @override
  Future<ReservationModel> create(CreateReservationRequest request) async {
    if (failWith != null) throw failWith!;

    final String existingId = _idByKey[request.idempotencyKey] ?? '';
    final ReservationModel? existing = _byId[existingId];
    if (existing != null) return existing;

    final int hash = _fnv1a(request.idempotencyKey);
    final String id = '${1000000 + (hash % 9000000)}';
    final String reference = _reference(hash);
    final DateTime now = _clock();

    final ReservationModel model = ReservationModel.fromJson(
      <String, Object?>{
        'id': id,
        'reference': reference,
        'hotel_id': request.hotelId,
        'room_type_id': request.roomTypeId,
        'room_id': request.roomId,
        'check_in': request.stay.checkIn.toIso8601String(),
        'check_out': request.stay.checkOut.toIso8601String(),
        'adults': request.party.adults,
        'children': request.party.children,
        'status': ReservationStatus.pending.wireValue,
        'price_snapshot': request.priceSnapshot.amount,
        'currency': request.priceSnapshot.currency,
        'created_at': now.toIso8601String(),
      },
      hotelName: request.hotelName,
      roomName: request.roomName,
      party: request.party,
    );

    _byId[id] = model;
    _idByKey[request.idempotencyKey] = id;
    return model;
  }

  @override
  Future<ReservationModel> fetchById(String id) async {
    if (failWith != null) throw failWith!;
    final ReservationModel? model = _byId[id];
    if (model == null) {
      throw NotFoundException('No reservation with id "$id"');
    }
    return model;
  }

  @override
  Future<List<ReservationModel>> fetchList() async {
    if (failWith != null) throw failWith!;
    final List<ReservationModel> all = _byId.values.toList(growable: false);
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  /// Mirrors the backend rule (`ReservationStateMachine`): only a reservation
  /// still short of check-in may be cancelled by the guest.
  static const Set<ReservationStatus> _cancellable = <ReservationStatus>{
    ReservationStatus.pending,
    ReservationStatus.depositHeld,
    ReservationStatus.verified,
  };

  @override
  Future<ReservationModel> cancel(String id) async {
    if (failWith != null) throw failWith!;
    final ReservationModel? model = _byId[id];
    if (model == null) {
      throw NotFoundException('No reservation with id "$id"');
    }
    if (!_cancellable.contains(model.status)) {
      throw const ConflictException(
        'This reservation can no longer be cancelled.',
      );
    }
    final ReservationModel cancelled = ReservationModel.fromJson(
      _toJson(model)
        ..['status'] = ReservationStatus.cancelled.wireValue
        ..['cancelled_at'] = _clock().toIso8601String(),
      hotelName: model.hotelName,
      roomName: model.roomName,
      party: GuestParty(adults: model.adults, children: model.children),
    );
    _byId[id] = cancelled;
    return cancelled;
  }

  /// Mirrors `ReservationExtensionService`: only a reservation the guest is
  /// currently occupying may be extended, and the new checkout date must be
  /// strictly after the current one. The dummy nightly rate stands in for
  /// `room_types.base_price`.
  static const Set<ReservationStatus> _extendable = <ReservationStatus>{
    ReservationStatus.checkedIn,
    ReservationStatus.inStay,
  };

  @override
  Future<ExtendStayResultModel> extend(ExtendStayRequest request) async {
    if (failWith != null) throw failWith!;
    final ReservationModel? model = _byId[request.reservationId];
    if (model == null) {
      throw NotFoundException('No reservation with id "${request.reservationId}"');
    }
    if (!_extendable.contains(model.status)) {
      throw const ConflictException(
        'A stay extension cannot be requested for this reservation.',
      );
    }
    if (!request.newCheckOut.isAfter(model.checkOut)) {
      throw const ConflictException(
        'The new checkout date must be after the current one.',
      );
    }

    final int nightsAdded = request.newCheckOut.difference(model.checkOut).inDays;
    final Money nightlyRate = model.nightlyRate ?? const Money(amount: 0);
    final Money amount = nightlyRate * nightsAdded;
    final Money newPriceSnapshot = Money(
      amount: model.priceSnapshot.amount + amount.amount,
      currency: model.priceSnapshot.currency,
    );

    final ReservationModel extended = ReservationModel.fromJson(
      _toJson(model)
        ..['check_out'] = request.newCheckOut.toIso8601String()
        ..['price_snapshot'] = newPriceSnapshot.amount,
      hotelName: model.hotelName,
      roomName: model.roomName,
      party: GuestParty(adults: model.adults, children: model.children),
    );
    _byId[request.reservationId] = extended;

    return ExtendStayResultModel(
      reservationId: request.reservationId,
      newCheckOut: request.newCheckOut,
      nightsAdded: nightsAdded,
      amount: amount,
      outstandingTotal: amount,
    );
  }

  /// Round-trips a [ReservationModel] back through the same JSON shape
  /// [ReservationModel.fromJson] parses, so [cancel] / [extend] can apply a
  /// small patch without hand-duplicating every field.
  Map<String, Object?> _toJson(ReservationModel model) => <String, Object?>{
        'id': model.id,
        'reference': model.reference,
        'hotel_id': model.hotelId,
        'room_type_id': model.roomTypeId,
        'room_id': model.roomId,
        'check_in': model.checkIn.toIso8601String(),
        'check_out': model.checkOut.toIso8601String(),
        'adults': model.adults,
        'children': model.children,
        'status': model.status.wireValue,
        'price_snapshot': model.priceSnapshot.amount,
        'currency': model.priceSnapshot.currency,
        'created_at': model.createdAt.toIso8601String(),
        'cancelled_at': model.cancelledAt?.toIso8601String(),
        'hotel': <String, Object?>{
          'city': model.hotelCity,
          'cover_url': model.hotelImageUrl,
          'deposit_amount': _sampleDeposit(model.priceSnapshot.amount),
        },
        'room': model.roomNumber == null
            ? null
            : <String, Object?>{'room_number': model.roomNumber},
        'room_type': model.nightlyRate == null
            ? null
            : <String, Object?>{'base_price': model.nightlyRate!.amount},
      };

  void _seedFixtures() {
    final DateTime now = _clock();
    DateTime days(int offset) => DateTime(now.year, now.month, now.day).add(Duration(days: offset));

    void seed({
      required String id,
      required String reference,
      required LocalizedText hotelName,
      required String hotelCity,
      required String hotelImageUrl,
      required ReservationStatus status,
      required DateTime checkIn,
      required DateTime checkOut,
      required int priceAmount,
      required int nightlyRateAmount,
      String? roomNumber,
      int createdOffsetDays = -5,
      int? cancelledOffsetDays,
    }) {
      final Json json = <String, Object?>{
        'id': id,
        'reference': reference,
        'hotel_id': 'hotel-$id',
        'room_type_id': 'room-type-$id',
        'room_id': roomNumber == null ? null : 'room-$id',
        'check_in': checkIn.toIso8601String(),
        'check_out': checkOut.toIso8601String(),
        'adults': 2,
        'children': 0,
        'status': status.wireValue,
        'price_snapshot': priceAmount,
        'currency': Money.fallbackCurrency,
        'created_at': days(createdOffsetDays).toIso8601String(),
        'cancelled_at':
            cancelledOffsetDays == null ? null : days(cancelledOffsetDays).toIso8601String(),
        'hotel': <String, Object?>{
          'city': hotelCity,
          'cover_url': hotelImageUrl,
          'deposit_amount': _sampleDeposit(priceAmount),
        },
        'room': roomNumber == null ? null : <String, Object?>{'room_number': roomNumber},
        'room_type': <String, Object?>{'base_price': nightlyRateAmount},
      };
      _byId[id] = ReservationModel.fromJson(
        json,
        hotelName: hotelName,
        roomName: const LocalizedText(ar: 'غرفة مزدوجة', en: 'Double room'),
        party: const GuestParty(adults: 2, children: 0),
      );
    }

    const LocalizedText oasis = LocalizedText(ar: 'فندق الواحة', en: 'Oasis Hotel');
    const LocalizedText marina = LocalizedText(ar: 'فندق المرسى', en: 'Marina Hotel');
    const LocalizedText palm = LocalizedText(ar: 'فندق النخيل', en: 'Palm Hotel');
    const String oasisImg =
        'https://images.unsplash.com/photo-1501117716987-c8e1ecb210af?w=200';
    const String marinaImg =
        'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=200';
    const String palmImg =
        'https://images.unsplash.com/photo-1512100356356-de1b84283e18?w=200';

    // Currently staying — BOOKING_Detail_CurrentlyStaying / STAY_Home.
    seed(
      id: 'seed-in-stay',
      reference: 'RSV-A1B-001',
      hotelName: oasis,
      hotelCity: 'Riyadh',
      hotelImageUrl: oasisImg,
      status: ReservationStatus.checkedIn,
      checkIn: days(-2),
      checkOut: days(2),
      priceAmount: 945,
      nightlyRateAmount: 315,
      roomNumber: '412',
      createdOffsetDays: -10,
    );

    // Ready to check in — verified, deposit secured + identity approved.
    seed(
      id: 'seed-verified',
      reference: 'RSV-B2C-002',
      hotelName: palm,
      hotelCity: 'Jeddah',
      hotelImageUrl: palmImg,
      status: ReservationStatus.verified,
      checkIn: days(3),
      checkOut: days(6),
      priceAmount: 1140,
      nightlyRateAmount: 380,
      createdOffsetDays: -3,
    );

    // Verification required — deposit held, identity not yet approved.
    seed(
      id: 'seed-deposit-held',
      reference: 'RSV-C3D-003',
      hotelName: marina,
      hotelCity: 'Dammam',
      hotelImageUrl: marinaImg,
      status: ReservationStatus.depositHeld,
      checkIn: days(28),
      checkOut: days(30),
      priceAmount: 1040,
      nightlyRateAmount: 520,
      createdOffsetDays: -1,
    );

    // Pending payment.
    seed(
      id: 'seed-pending',
      reference: 'RSV-D4E-004',
      hotelName: marina,
      hotelCity: 'Dammam',
      hotelImageUrl: marinaImg,
      status: ReservationStatus.pending,
      checkIn: days(45),
      checkOut: days(47),
      priceAmount: 1040,
      nightlyRateAmount: 520,
      createdOffsetDays: 0,
    );

    // Cancelled.
    seed(
      id: 'seed-cancelled',
      reference: 'RSV-E5F-005',
      hotelName: marina,
      hotelCity: 'Dammam',
      hotelImageUrl: marinaImg,
      status: ReservationStatus.cancelled,
      checkIn: days(-16),
      checkOut: days(-14),
      priceAmount: 1040,
      nightlyRateAmount: 520,
      createdOffsetDays: -20,
      cancelledOffsetDays: -18,
    );

    // Past / completed — grouped in the Bookings "Past" tab.
    seed(
      id: 'seed-completed-1',
      reference: 'RSV-F6G-006',
      hotelName: oasis,
      hotelCity: 'Riyadh',
      hotelImageUrl: oasisImg,
      status: ReservationStatus.checkedOut,
      checkIn: days(-30),
      checkOut: days(-28),
      priceAmount: 1065,
      nightlyRateAmount: 355,
      createdOffsetDays: -40,
    );
    seed(
      id: 'seed-completed-2',
      reference: 'RSV-G7H-007',
      hotelName: palm,
      hotelCity: 'Jeddah',
      hotelImageUrl: palmImg,
      status: ReservationStatus.invoiced,
      checkIn: days(-70),
      checkOut: days(-65),
      priceAmount: 1420,
      nightlyRateAmount: 284,
      createdOffsetDays: -80,
    );
    seed(
      id: 'seed-completed-3',
      reference: 'RSV-H8I-008',
      hotelName: marina,
      hotelCity: 'Dammam',
      hotelImageUrl: marinaImg,
      status: ReservationStatus.checkedOut,
      checkIn: days(-95),
      checkOut: days(-93),
      priceAmount: 860,
      nightlyRateAmount: 430,
      createdOffsetDays: -100,
    );
  }

  /// Offline sample of the server-computed `hotel.deposit_amount` (the
  /// backend uses each hotel's configured `deposit_percentage`; 20% here is
  /// only the dummy's sample hotel setting).
  static num _sampleDeposit(num price) => (price * 20).round() / 100;

  static int _fnv1a(String value) {
    int hash = 0x811c9dc5;
    for (final int unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static String _reference(int hash) {
    final String base = hash.toRadixString(36).toUpperCase().padLeft(6, '0');
    final String body = base.substring(base.length - 6);
    return 'RSV-${body.substring(0, 3)}-${body.substring(3)}';
  }
}
