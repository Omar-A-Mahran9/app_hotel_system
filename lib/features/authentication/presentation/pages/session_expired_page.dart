import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../state/auth_controller.dart';
import '../state/login_flow_controller.dart';

/// `09 · Authentication` — "Session ended". Reached when the backend rejects a
/// stored token (a later-phase API concern). The booking is untouched; the
/// guest signs in again and the app resumes where they left off.
///
/// Phase 1 note: the reference also shows a summary of the saved reservation on
/// this screen. That data belongs to the reservations phase, so it is omitted
/// here and tracked as an open question.
class SessionExpiredPage extends ConsumerWidget {
  const SessionExpiredPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;

    return Scaffold(
      appBar: HotelAppBar(title: l10n.authSessionExpiredTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pageGutter),
          children: <Widget>[
            InfoBanner(
              tone: InfoBannerTone.warning,
              title: l10n.authSessionExpiredBannerTitle,
              message: l10n.authSessionExpiredBannerBody,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: l10n.authSessionExpiredSubmit,
              onPressed: () {
                ref.read(loginFlowControllerProvider.notifier).reset();
                ref.read(authControllerProvider.notifier).acknowledgeExpiry();
              },
            ),
          ],
        ),
      ),
    );
  }
}
