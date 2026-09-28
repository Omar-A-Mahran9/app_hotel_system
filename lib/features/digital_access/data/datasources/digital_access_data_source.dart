import '../../domain/entities/check_in.dart';
import '../models/digital_access_models.dart';

/// The digital-access data contract. Dummy + API implementations selected by DI
/// (`AppConfig.useDummyData`), exactly like `PaymentDataSource`.
abstract interface class DigitalAccessDataSource {
  Future<AccessGrantModel?> fetchGrant(String reservationId);

  Future<AccessGrantModel> checkIn(CheckInRequest request);
}
