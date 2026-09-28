import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/core_providers.dart';
import '../../data/datasources/api_app_content_data_source.dart';
import '../../data/datasources/app_content_data_source.dart';
import '../../data/datasources/dummy_app_content_data_source.dart';
import '../../data/repositories/app_content_repository_impl.dart';
import '../../domain/entities/app_content.dart';
import '../../domain/repositories/app_content_repository.dart';

final appContentDataSourceProvider = Provider<AppContentDataSource>((Ref ref) {
  final AppConfig config = ref.watch(appConfigProvider);
  return config.useDummyData
      ? const DummyAppContentDataSource()
      : ApiAppContentDataSource(ref.watch(apiClientProvider));
});

final appContentRepositoryProvider = Provider<AppContentRepository>(
  (Ref ref) =>
      AppContentRepositoryImpl(ref.watch(appContentDataSourceProvider)),
);

/// How long the entry screens wait for dashboard content before settling on
/// the bundled defaults. The splash already holds for 1.6s, so a normal
/// response lands well inside this.
const Duration appContentTimeout = Duration(seconds: 3);

/// The Guest App's dashboard-managed branding + entry content, fetched once
/// per launch (kept alive for the session).
///
/// Branding must never block entry: any failure or a slow response resolves
/// to [AppContent.empty], so every screen falls back to its bundled defaults.
final appContentProvider = FutureProvider<AppContent>((Ref ref) async {
  try {
    return await ref
        .watch(appContentRepositoryProvider)
        .content()
        .timeout(appContentTimeout);
  } catch (error) {
    if (kDebugMode) debugPrint('appContent: using bundled defaults — $error');
    return AppContent.empty;
  }
});

/// The FAQ for `PROFILE_Support` — fetched fresh, and unlike
/// [appContentProvider] a failure is surfaced (with retry) instead of
/// silently showing "no questions".
final faqProvider = FutureProvider.autoDispose<List<FaqEntry>>((Ref ref) async {
  final AppContent content = await ref.watch(appContentRepositoryProvider).content();
  return content.faq;
});
