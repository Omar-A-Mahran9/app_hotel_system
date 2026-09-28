import '../../../../core/data/data_source.dart';
import '../../domain/entities/app_content.dart';
import 'app_content_data_source.dart';

/// Dummy source: behaves like a backend where nothing has been configured in
/// the dashboard yet, so every entry screen shows its bundled Figma defaults.
class DummyAppContentDataSource
    implements AppContentDataSource, DummyDataSource {
  const DummyAppContentDataSource({this.content = AppContent.empty});

  final AppContent content;

  @override
  Future<AppContent> fetchContent() async => content;
}
