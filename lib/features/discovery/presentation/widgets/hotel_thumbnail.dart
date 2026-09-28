import 'package:flutter/material.dart';

import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_icons.dart';

/// Hotel / room imagery for cards, heroes and list rows.
///
/// Backed by [AppImage.network]: [imageUrl] is the real `logo_url` /
/// `cover_url` / gallery `url` the backend returned for this hotel/room.
/// `null` renders the branded placeholder — UNLESS [seed] is also given, in
/// which case it renders a deterministic Figma-sourced photo instead
/// ([AppImage.seeded]) for dummy/demo screens that have no per-entity photo
/// field to read yet (e.g. the Home hotel grid). Real-API call sites must
/// never pass [seed] — that would fake per-entity imagery
/// (mobile/docs — real-API mode must never fake per-entity imagery). A
/// network failure degrades to the same branded placeholder.
class HotelThumbnail extends StatelessWidget {
  const HotelThumbnail({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.borderRadius,
    this.icon = AppIcons.hotel,
    this.seed,
  });

  final String? imageUrl;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final IconData icon;

  /// Dummy-mode-only deterministic photo key (e.g. the hotel id). Ignored
  /// when [imageUrl] is non-null.
  final String? seed;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null && seed != null) {
      return AppImage.seeded(
        seed: seed!,
        pool: AppImages.scenic,
        width: width,
        height: height,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        fallbackIcon: icon,
      );
    }
    return AppImage.network(
      url: imageUrl,
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      fallbackIcon: icon,
    );
  }
}
