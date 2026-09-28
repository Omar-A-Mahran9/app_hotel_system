import '../localization/l10n.dart';
import 'failure.dart';

/// Maps a [Failure] to a localized, user-safe sentence. This is the only place
/// error copy is chosen; widgets pass the [AppLocalizations] instance in.
extension FailureL10n on Failure {
  String localizedMessage(AppLocalizations l10n) => switch (kind) {
        FailureKind.network => l10n.errorNetwork,
        FailureKind.timeout => l10n.errorTimeout,
        FailureKind.unauthorized => l10n.errorUnauthorized,
        FailureKind.server => l10n.errorServer,
        FailureKind.notImplemented => l10n.errorNotImplemented,
        FailureKind.forbidden ||
        FailureKind.notFound ||
        FailureKind.validation ||
        FailureKind.conflict ||
        FailureKind.rateLimited ||
        FailureKind.unknown =>
          l10n.errorGeneric,
      };
}
