import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/banner_screen.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../authentication/presentation/state/auth_controller.dart';

/// `PROFILE_Logout_Confirm_Overlay` ("تسجيل الخروج"). Confirming revokes the
/// token on the backend (`POST /guest/auth/logout`) and clears the local
/// session; the router then lands on sign-in.
class LogoutConfirmPage extends ConsumerStatefulWidget {
  const LogoutConfirmPage({super.key});

  @override
  ConsumerState<LogoutConfirmPage> createState() => _LogoutConfirmPageState();
}

class _LogoutConfirmPageState extends ConsumerState<LogoutConfirmPage> {
  bool _busy = false;

  Future<void> _signOut() async {
    setState(() => _busy = true);
    final Failure? failure = await ref.read(authControllerProvider.notifier).signOut();
    // Signed out locally either way; an unreachable server only means the
    // token will expire server-side instead of being revoked now.
    if (failure != null) debugPrint('Logout revoke failed: ${failure.kind}');
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return BannerScreen(
      title: l10n.authSignOut,
      tone: InfoBannerTone.warning,
      bannerTitle: l10n.profileLogoutConfirmTitle,
      bannerMessage: l10n.profileLogoutConfirmBody,
      primaryLabel: l10n.authSignOut,
      primaryLoading: _busy,
      onPrimary: _busy ? null : _signOut,
    );
  }
}
