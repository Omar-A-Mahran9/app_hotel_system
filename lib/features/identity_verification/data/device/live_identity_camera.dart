import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/identity_document.dart';
import 'identity_camera.dart';

/// An [IdentityCamera] that can also show the camera feed live, inside the
/// capture frame, so the guest lines the card (or face) up before the shot.
///
/// Only the real device camera implements this; the test fake doesn't, so
/// widget tests keep the one-shot [IdentityCamera.capture] path.
abstract interface class LiveIdentityCamera implements IdentityCamera {
  /// Whether a live viewfinder can be opened on this platform at all.
  bool get supportsLiveViewfinder;

  IdentityViewfinder openViewfinder(IdentityCaptureTarget target);
}

enum IdentityViewfinderStatus { initializing, ready, unavailable }

/// One live camera session for a capture step. Owned (and disposed) by the
/// widget showing it.
abstract class IdentityViewfinder extends ChangeNotifier {
  IdentityViewfinderStatus get status;

  /// Set when [status] is [IdentityViewfinderStatus.unavailable].
  IdentityCameraUnavailable? get problem;

  Future<void> start();

  /// Releases the camera while the app is in the background.
  Future<void> pause();

  /// The camera feed, filling (and clipped to) the box it is laid out in.
  Widget buildPreview();

  Future<IdentityCaptureResult> takePicture();
}

/// [IdentityViewfinder] backed by the `camera` package. The photo is written
/// to an on-device temp file — never held as bytes (architecture.md §8).
class CameraPackageViewfinder extends IdentityViewfinder {
  CameraPackageViewfinder(this.target);

  final IdentityCaptureTarget target;

  CameraController? _controller;
  IdentityViewfinderStatus _status = IdentityViewfinderStatus.initializing;
  IdentityCameraUnavailable? _problem;
  bool _busy = false;
  bool _disposed = false;

  @override
  IdentityViewfinderStatus get status => _status;

  @override
  IdentityCameraUnavailable? get problem => _problem;

  @override
  Future<void> start() async {
    if (_disposed || _controller != null) return;
    _set(IdentityViewfinderStatus.initializing);
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) {
        _fail(permissionDenied: false);
        return;
      }
      final CameraLensDirection wanted = target == IdentityCaptureTarget.selfie
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      final CameraDescription camera = cameras.firstWhere(
        (CameraDescription c) => c.lensDirection == wanted,
        orElse: () => cameras.first,
      );
      final CameraController controller = CameraController(
        camera,
        // 1080p: sharp enough for the ID text, well under the upload limit.
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _controller = controller;
      await controller.initialize();
      if (_disposed) {
        await controller.dispose();
        return;
      }
      _set(IdentityViewfinderStatus.ready);
    } on CameraException catch (e) {
      debugPrint('Identity viewfinder failed: ${e.code}');
      await _release();
      _fail(permissionDenied: e.code.startsWith('CameraAccess'));
    } catch (e) {
      // No camera plugin / hardware (e.g. a simulator).
      debugPrint('Identity viewfinder unavailable: ${e.runtimeType}');
      await _release();
      _fail(permissionDenied: false);
    }
  }

  @override
  Future<void> pause() => _release();

  @override
  Widget buildPreview() {
    final CameraController? c = _controller;
    if (c == null || !c.value.isInitialized) return const SizedBox.expand();
    // `aspectRatio` is landscape (w/h); the phone is held upright.
    final Size sensor = Size(c.value.previewSize?.height ?? 9, c.value.previewSize?.width ?? 16);
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(width: sensor.width, height: sensor.height, child: CameraPreview(c)),
      ),
    );
  }

  @override
  Future<IdentityCaptureResult> takePicture() async {
    final CameraController? c = _controller;
    if (c == null || !c.value.isInitialized || _busy) {
      return const IdentityCaptureCancelled();
    }
    _busy = true;
    try {
      final XFile file = await c.takePicture();
      return IdentityCaptured(
        CapturedImage(
          label: target == IdentityCaptureTarget.selfie ? 'selfie.jpg' : 'document.jpg',
          sizeBytes: await file.length(),
          mimeType: 'image/jpeg',
          filePath: file.path,
        ),
      );
    } on CameraException catch (e) {
      debugPrint('Identity capture failed: ${e.code}');
      return IdentityCameraUnavailable(permissionDenied: e.code.startsWith('CameraAccess'));
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _release();
    super.dispose();
  }

  Future<void> _release() async {
    final CameraController? c = _controller;
    _controller = null;
    if (c != null) await c.dispose();
    if (!_disposed && _status == IdentityViewfinderStatus.ready) {
      _set(IdentityViewfinderStatus.initializing);
    }
  }

  void _fail({required bool permissionDenied}) {
    _problem = IdentityCameraUnavailable(permissionDenied: permissionDenied);
    _set(IdentityViewfinderStatus.unavailable);
  }

  void _set(IdentityViewfinderStatus s) {
    if (_disposed) return;
    _status = s;
    notifyListeners();
  }
}

/// Hosts a live camera session for as long as it is on screen: opens it
/// ([LiveIdentityCamera.openViewfinder]) on mount, releases the camera in the
/// background and on unmount. The page takes the photo through a
/// `GlobalKey<IdentityLiveViewfinderState>`.
class IdentityLiveViewfinder extends StatefulWidget {
  const IdentityLiveViewfinder({
    super.key,
    required this.camera,
    required this.target,
    required this.onUnavailable,
  });

  final LiveIdentityCamera camera;
  final IdentityCaptureTarget target;

  /// The camera couldn't be opened (denied, missing, failed).
  final ValueChanged<IdentityCameraUnavailable> onUnavailable;

  @override
  State<IdentityLiveViewfinder> createState() => IdentityLiveViewfinderState();
}

class IdentityLiveViewfinderState extends State<IdentityLiveViewfinder>
    with WidgetsBindingObserver {
  late final IdentityViewfinder _viewfinder = widget.camera.openViewfinder(widget.target);
  bool _reported = false;

  bool get isReady => _viewfinder.status == IdentityViewfinderStatus.ready;

  Future<IdentityCaptureResult> takePicture() => _viewfinder.takePicture();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewfinder.addListener(_onChange);
    // After the first frame: a failure reports to the page (setState), which
    // must not happen while it is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _viewfinder.start();
    });
  }

  void _onChange() {
    final IdentityCameraUnavailable? problem = _viewfinder.problem;
    if (!_reported && problem != null && _viewfinder.status == IdentityViewfinderStatus.unavailable) {
      _reported = true;
      widget.onUnavailable(problem);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _viewfinder.pause();
    } else if (state == AppLifecycleState.resumed) {
      _viewfinder.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewfinder.removeListener(_onChange);
    _viewfinder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewfinder,
      builder: (BuildContext context, _) => switch (_viewfinder.status) {
        IdentityViewfinderStatus.ready => _viewfinder.buildPreview(),
        IdentityViewfinderStatus.initializing => const Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
            ),
          ),
        IdentityViewfinderStatus.unavailable => const SizedBox.expand(),
      },
    );
  }
}

/// The app's device camera: a live viewfinder on iOS/Android, with
/// `image_picker` ([ImagePickerIdentityCamera.capture]) as the fallback when
/// it can't open — and as the only path on the web, where the guest picks a
/// file.
class DeviceIdentityCamera extends ImagePickerIdentityCamera implements LiveIdentityCamera {
  DeviceIdentityCamera([super.picker]);

  @override
  bool get supportsLiveViewfinder => !kIsWeb;

  @override
  IdentityViewfinder openViewfinder(IdentityCaptureTarget target) =>
      CameraPackageViewfinder(target);
}
