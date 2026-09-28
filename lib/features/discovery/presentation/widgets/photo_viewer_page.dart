import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icons.dart';
import '../../../../core/widgets/app_image.dart';
import 'hero_circle_button.dart';

/// Full-screen, pinch-zoomable view of a single hotel/room photo — opened by
/// tapping the `HOTEL_Detail` hero image. A transient overlay rather than a
/// deep-linkable screen, so it isn't a named `go_router` route: push it with
/// `Navigator.of(context).push(PhotoViewerPage.route(url))`.
class PhotoViewerPage extends StatelessWidget {
  const PhotoViewerPage({super.key, required this.imageUrl});

  final String? imageUrl;

  static Route<void> route(String? imageUrl) {
    return MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (BuildContext _) => PhotoViewerPage(imageUrl: imageUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: AppImage.network(
                  url: imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.contain,
                  borderRadius: BorderRadius.zero,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: HeroCircleButton(
                  icon: AppIcons.close,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
