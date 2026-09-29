import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_icons.dart';
import 'bottom_action_bar.dart';
import 'hotel_app_bar.dart';
import 'info_banner.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

/// The Figma's shared full-screen state shell: a title bar, one tinted
/// [InfoBanner] explaining the state, empty breathing room, and up to two
/// actions pinned at the bottom. Reused across the identity (Intro / Uploading
/// / Success / Failed_* / ContactReception), services (ServiceCancel_Confirm),
/// profile (Logout_Confirm) and report-a-problem boards — one shell,
/// different tone/copy/actions.
class BannerScreen extends StatelessWidget {
  const BannerScreen({
    super.key,
    required this.title,
    required this.tone,
    required this.bannerTitle,
    required this.bannerMessage,
    this.primaryLabel,
    this.onPrimary,
    this.primaryLoading = false,
    this.secondaryLabel,
    this.onSecondary,
    this.linkLabel,
    this.onLink,
    this.onClose,
  });

  final String title;
  final InfoBannerTone tone;
  final String bannerTitle;
  final String bannerMessage;

  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryLoading;

  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// An optional low-emphasis way out under the banner (e.g. "contact
  /// reception") when the two actions may not get the guest unstuck.
  final String? linkLabel;
  final VoidCallback? onLink;

  /// The app bar's ✕. Defaults to popping the route.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // v2: a ✕ at the end of the bar, no back arrow.
      appBar: HotelAppBar(
        title: title,
        automaticallyImplyLeading: false,
        actions: <Widget>[
          IconButton(
            icon: const Icon(AppIcons.dismiss, size: 22),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onClose ?? () => Navigator.maybePop(context),
          ),
          const SizedBox(width: AppSpacing.space3),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.space6,
            AppSpacing.pageGutter,
            0,
          ),
          // The banner hugs its copy; the rest of the screen stays empty.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              InfoBanner(tone: tone, title: bannerTitle, message: bannerMessage),
              if (linkLabel != null) ...<Widget>[
                const SizedBox(height: AppSpacing.space3),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: onLink,
                    child: Text(
                      linkLabel!,
                      style: const TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: (primaryLabel == null && secondaryLabel == null)
          ? null
          : BottomActionBar.actions(
              primary: primaryLabel == null
                  ? const SizedBox.shrink()
                  : PrimaryButton(
                      label: primaryLabel!,
                      onPressed: onPrimary,
                      isLoading: primaryLoading,
                    ),
              secondary: secondaryLabel == null
                  ? null
                  : SecondaryButton(label: secondaryLabel!, onPressed: onSecondary),
            ),
    );
  }
}
