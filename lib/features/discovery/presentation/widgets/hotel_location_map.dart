import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_icons.dart';
import 'hero_circle_button.dart';

/// OpenStreetMap raster tiles — the same source the dashboard's location
/// picker uses (Leaflet), so staff and guests see the same map.
const String _osmTiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Identifies the app to the OSM tile servers (required by their usage policy).
const String _userAgentPackage = 'com.hotelsystem.hotel_guest_app';

/// A live map of the hotel's real coordinates (set by staff in the
/// dashboard's Location map) with the Figma's white pin.
///
/// [interactive] `false` is the Hotel Detail card preview: a fixed view that
/// never steals the page's scroll gesture, which opens [HotelMapPage] on tap.
class HotelLocationMap extends StatelessWidget {
  const HotelLocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.interactive = false,
    this.zoom = 15,
  });

  final double latitude;
  final double longitude;
  final bool interactive;
  final double zoom;

  /// Whether the OSM tile layer is drawn — always in the app. Widget tests
  /// turn it off (`test/flutter_test_config.dart`): tiles can't load there,
  /// and the tile loader's real network / on-disk cache I/O can hold a test
  /// process open for minutes. The pin, attribution and taps still render.
  @visibleForTesting
  static bool tilesEnabled = true;

  @override
  Widget build(BuildContext context) {
    final LatLng point = LatLng(latitude, longitude);
    return FlutterMap(
      options: MapOptions(
        initialCenter: point,
        initialZoom: zoom,
        minZoom: 3,
        maxZoom: 19,
        interactionOptions: InteractionOptions(
          flags: interactive
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.none,
        ),
      ),
      children: <Widget>[
        if (tilesEnabled)
          TileLayer(
            urlTemplate: _osmTiles,
            userAgentPackageName: _userAgentPackage,
          ),
        MarkerLayer(
          markers: <Marker>[
            Marker(point: point, width: 44, height: 44, child: const _Pin()),
          ],
        ),
        const _Attribution(),
      ],
    );
  }
}

/// Full-screen, pannable/zoomable hotel map — opened by tapping the Hotel
/// Detail location preview. A transient overlay (like `PhotoViewerPage`),
/// not a deep-linkable route.
class HotelMapPage extends StatelessWidget {
  const HotelMapPage({
    super.key,
    required this.latitude,
    required this.longitude,
    this.title,
  });

  final double latitude;
  final double longitude;
  final String? title;

  static Route<void> route({
    required double latitude,
    required double longitude,
    String? title,
  }) {
    return MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (BuildContext _) =>
          HotelMapPage(latitude: latitude, longitude: longitude, title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: HotelLocationMap(
              latitude: latitude,
              longitude: longitude,
              interactive: true,
              zoom: 16,
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

/// The Figma `mini-map` pin: a white 44px circle (no shadow) with the 24px
/// Hicon `Linear / Location` glyph.
class _Pin extends StatelessWidget {
  const _Pin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppPrimitives.white,
        shape: BoxShape.circle,
      ),
      child: Icon(AppIcons.mapPin, size: 24, color: context.colors.textPrimary),
    );
  }
}

/// "© OpenStreetMap contributors" — required wherever OSM tiles are shown.
class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.bottomEnd,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppPrimitives.white.withValues(alpha: 0.8),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
        child: Text(
          context.l10n.mapAttribution,
          style: const TextStyle(fontSize: 10, color: AppPrimitives.stone700),
        ),
      ),
    );
  }
}
