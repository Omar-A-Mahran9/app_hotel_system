import 'package:hotel_guest_app/features/identity_verification/data/datasources/dummy_identity_verification_data_source.dart';

/// The first reservation id (`v0`, `v1`, …) that maps to [scenario].
String reservationIdForScenario(DummyVerificationScenario scenario) {
  for (int i = 0; i < 500; i++) {
    final String id = 'v$i';
    if (DummyIdentityVerificationDataSource.scenarioFor(id) == scenario) {
      return id;
    }
  }
  throw StateError('no id found for $scenario');
}
