import '../entities/app_content.dart';

abstract interface class AppContentRepository {
  /// The current branding + entry content. Throws a `Failure` on error.
  Future<AppContent> content();
}
