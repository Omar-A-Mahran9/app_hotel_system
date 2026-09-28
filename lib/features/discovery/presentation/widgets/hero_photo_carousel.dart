import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/hotel_detail_provider.dart';
import 'hotel_thumbnail.dart';
import 'photo_viewer_page.dart';

/// The hero photo pager: swipeable through [photos] left/right, kept in sync
/// with [heroPhotoIndexProvider] (keyed by [entityId]) — swiping updates the
/// index (which drives the v2 `1/N` counter), and an external index change
/// animates the pager to match. Tapping opens the current photo full-screen
/// ([PhotoViewerPage]).
///
/// Shared by `HOTEL_Detail_Premium` (keyed by hotel id) and
/// `ROOM_Detail_Premium` (keyed by room-type id) via [DetailHeroCard] — both
/// heroes behave identically, just over a different entity's real photos.
class HeroPhotoCarousel extends ConsumerStatefulWidget {
  const HeroPhotoCarousel({
    super.key,
    required this.entityId,
    required this.photos,
    required this.height,
  });

  final String entityId;
  final List<String> photos;
  final double height;

  @override
  ConsumerState<HeroPhotoCarousel> createState() => _HeroPhotoCarouselState();
}

class _HeroPhotoCarouselState extends ConsumerState<HeroPhotoCarousel> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    final int initial = ref.read(heroPhotoIndexProvider(widget.entityId));
    _controller = PageController(
      initialPage: initial.clamp(0, _lastPageOrZero),
    );
  }

  int get _lastPageOrZero =>
      widget.photos.isEmpty ? 0 : widget.photos.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // An external change to the provider's index (not via this widget's own
    // `onPageChanged`) — animate the hero to match. The
    // guard against re-driving the controller when it's already there (from
    // the reverse direction, a swipe) avoids a feedback loop.
    ref.listen<int>(heroPhotoIndexProvider(widget.entityId), (_, int next) {
      if (!_controller.hasClients) return;
      final int current = _controller.page?.round() ?? _controller.initialPage;
      if (current == next) return;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });

    if (widget.photos.isEmpty) {
      return GestureDetector(
        onTap: () =>
            Navigator.of(context).push<void>(PhotoViewerPage.route(null)),
        child: HotelThumbnail(
          imageUrl: null,
          width: double.infinity,
          height: widget.height,
          borderRadius: BorderRadius.zero,
        ),
      );
    }

    return PageView.builder(
      controller: _controller,
      itemCount: widget.photos.length,
      onPageChanged: (int i) => ref
          .read(heroPhotoIndexProvider(widget.entityId).notifier)
          .state = i,
      itemBuilder: (BuildContext context, int i) => GestureDetector(
        onTap: () => Navigator.of(context)
            .push<void>(PhotoViewerPage.route(widget.photos[i])),
        child: HotelThumbnail(
          imageUrl: widget.photos[i],
          width: double.infinity,
          height: widget.height,
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}
