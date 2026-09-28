import 'package:hotel_guest_app/features/identity_verification/data/device/identity_camera.dart';
import 'package:hotel_guest_app/features/identity_verification/domain/entities/identity_document.dart';

/// Stands in for the device camera in `flutter test`: every capture returns
/// [result] (a file-less dummy photo by default) and is counted.
class FakeIdentityCamera implements IdentityCamera {
  FakeIdentityCamera({this.result = const IdentityCaptured(CapturedImage.dummy)});

  IdentityCaptureResult result;
  final List<IdentityCaptureTarget> captures = <IdentityCaptureTarget>[];

  @override
  Future<IdentityCaptureResult> capture(IdentityCaptureTarget target) async {
    captures.add(target);
    return result;
  }
}
