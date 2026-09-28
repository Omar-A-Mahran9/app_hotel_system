import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/l10n.dart';

/// The Hotel Detail hero `share-button`.
///
/// Opens the platform share sheet (Android/iOS; the Web Share API on web)
/// with the hotel's name, location and — when it has coordinates — a map
/// link. Where no share sheet is available (or it fails), the same text is
/// copied to the clipboard and a snackbar says so.
Future<void> shareHotel(
  BuildContext context, {
  required String name,
  required String location,
  double? latitude,
  double? longitude,
}) async {
  final String text = hotelShareText(
    name: name,
    location: location,
    latitude: latitude,
    longitude: longitude,
  );
  final RenderBox? box = context.findRenderObject() as RenderBox?;
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  final String copied = context.l10n.hotelShareCopied;

  try {
    final ShareResult result = await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: name,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
    if (result.status != ShareResultStatus.unavailable) return;
  } catch (_) {
    // No share sheet on this platform — fall through to the clipboard.
  }

  await Clipboard.setData(ClipboardData(text: text));
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(copied)));
}

/// `name`, `location` and a map link, one per line (blank parts dropped).
@visibleForTesting
String hotelShareText({
  required String name,
  required String location,
  double? latitude,
  double? longitude,
}) {
  return <String>[
    name,
    location,
    if (latitude != null && longitude != null)
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
  ].where((String line) => line.trim().isNotEmpty).join('\n');
}
