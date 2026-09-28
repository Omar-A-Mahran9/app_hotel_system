import 'package:hotel_guest_app/core/config/app_config.dart';
import 'package:hotel_guest_app/core/config/app_environment.dart';

/// A deterministic [AppConfig] for tests: development environment, dummy data,
/// no real network.
const AppConfig testConfig = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: 'http://localhost',
  apiVersion: 'v1',
  useDummyData: true,
);
