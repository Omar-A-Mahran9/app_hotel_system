import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/message_view.dart';
import '../state/login_flow_controller.dart';
import '../state/post_auth_redirect_controller.dart';

/// Body shown on a guest-only bottom-nav tab (Bookings, Services) while the
/// guest is signed out (`docs/mobile-deferred-auth.md`). Uses the `07 · Error &
/// Empty States` empty-state layout; the CTA remembers the current tab so the
/// router returns the guest here after phone → OTP → (profile).
class SignInRequiredView extends ConsumerWidget {
  const SignInRequiredView({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    return MessageView(
      icon: icon,
      title: l10n.guestSignInRequiredTitle,
      message: message,
      actionLabel: l10n.guestSignInAction,
      onAction: () {
        ref
            .read(postAuthRedirectProvider.notifier)
            .remember(GoRouterState.of(context).uri.toString());
        ref.read(loginFlowControllerProvider.notifier).reset();
        context.goNamed(AppRoutes.signInName);
      },
    );
  }
}
