import '../../../../core/widgets/banner_screen.dart';

/// The identity-verification state screens (`10 · Identity verification`) —
/// the shared [BannerScreen] shell.
class IdentityInfoScreen extends BannerScreen {
  const IdentityInfoScreen({
    super.key,
    required super.title,
    required super.tone,
    required super.bannerTitle,
    required super.bannerMessage,
    super.primaryLabel,
    super.onPrimary,
    super.primaryLoading,
    super.secondaryLabel,
    super.onSecondary,
    super.onClose,
  });
}
