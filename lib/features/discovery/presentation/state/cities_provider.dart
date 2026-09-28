import '../../../../core/localization/content_language_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/city.dart';
import 'discovery_providers.dart';

/// The group's destinations, for the city filter sheet and search suggestions.
/// A `FutureProvider` because the list is read-only and rarely changes.
final citiesProvider = FutureProvider<List<City>>(
  (Ref ref) {
  // Refetch in the new language after a language switch.
  ref.watch(contentLanguageProvider);
    return ref.watch(discoveryRepositoryProvider).cities();
  },
);
