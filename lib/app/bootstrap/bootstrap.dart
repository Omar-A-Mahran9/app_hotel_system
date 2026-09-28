import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/di/core_providers.dart';
import '../app.dart';

/// Single startup path for every entry point.
///
/// Responsibilities: bind the framework, build [AppConfig] from compile-time
/// defines, install top-level error handlers, and run the app inside a
/// [ProviderScope] with configuration injected.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppConfig config = AppConfig.fromEnvironment();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _report('flutter', details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _report('platform', error, stack);
    return true;
  };

  runApp(
    ProviderScope(
      overrides: <Override>[
        appConfigProvider.overrideWithValue(config),
      ],
      child: const HotelGuestApp(),
    ),
  );
}

/// Phase 0 crash sink: logs in debug only. A real crash-reporting integration
/// (behind an abstraction, opt-in, no PII) is a later-phase concern.
void _report(String source, Object error, StackTrace? stack) {
  if (kDebugMode) {
    developer.log('Uncaught ($source)', error: error, stackTrace: stack, name: 'app');
  }
}
