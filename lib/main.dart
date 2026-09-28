import 'app/bootstrap/bootstrap.dart';

/// Default entry point (development configuration).
///
/// Environment-specific entry points (e.g. `main_staging.dart`) can call
/// [bootstrap] after setting their own `--dart-define`s; there is no per-flavor
/// logic in code.
void main() => bootstrap();
