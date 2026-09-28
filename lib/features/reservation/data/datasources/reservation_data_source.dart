import '../../domain/entities/create_reservation_request.dart';
import '../../domain/entities/extend_stay.dart';
import '../models/reservation_models.dart';

/// The reservation data contract. Dummy + API implementations, selected by DI
/// (`AppConfig.useDummyData`) exactly like `DiscoveryDataSource` /
/// `AuthDataSource`. Methods return DTO models; the repository maps them to
/// domain entities.
abstract interface class ReservationDataSource {
  Future<ReservationModel> create(CreateReservationRequest request);

  Future<ReservationModel> fetchById(String id);

  /// The guest's own reservations, newest first.
  Future<List<ReservationModel>> fetchList();

  /// Cancels a reservation the guest may still cancel. The backend enforces
  /// which statuses allow it (pending / deposit_held / verified); anything
  /// else surfaces as a `Failure` the repository maps for the UI.
  Future<ReservationModel> cancel(String id);

  /// Requests a stay extension. Returns the authoritative outcome — the app
  /// never computes the incremental amount itself.
  Future<ExtendStayResultModel> extend(ExtendStayRequest request);
}
