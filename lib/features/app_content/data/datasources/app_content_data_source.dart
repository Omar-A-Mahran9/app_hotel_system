import '../../domain/entities/app_content.dart';

/// The app-content data contract. Dummy + API implementations, selected by DI
/// (`AppConfig.useDummyData`).
abstract interface class AppContentDataSource {
  Future<AppContent> fetchContent();
}
