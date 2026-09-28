import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'info_banner.dart';

/// The Figma result-screen body: a tinted [InfoBanner] header (success / error /
/// warning / info) with an optional detail block beneath it. Pair with
/// `BottomActionBar` for the actions.
///
/// Replaces the ad-hoc `CircleAvatar` + centred-text heroes that several result
/// screens grew independently.
class ResultView extends StatelessWidget {
  const ResultView({
    super.key,
    required this.tone,
    required this.title,
    this.message,
    this.detail,
    this.padding = const EdgeInsets.all(AppSpacing.pageGutter),
  });

  final InfoBannerTone tone;
  final String title;
  final String? message;

  /// Optional content shown below the banner (a summary card, a status row).
  final Widget? detail;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      children: <Widget>[
        InfoBanner(tone: tone, title: title, message: message),
        if (detail != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          detail!,
        ],
      ],
    );
  }

  /// Maps a semantic outcome to the banner tone.
  static InfoBannerTone toneFor({
    bool success = false,
    bool pending = false,
    bool error = false,
  }) {
    if (error) return InfoBannerTone.error;
    if (success) return InfoBannerTone.success;
    if (pending) return InfoBannerTone.warning;
    return InfoBannerTone.info;
  }
}
