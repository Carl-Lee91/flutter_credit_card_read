import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraUtils {
  static InputImage? convertCameraImageToInputImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final InputImageRotation? imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (imageRotation == null) return null;

    // [수정된 부분] 자동 감지 대신 플랫폼별로 포맷을 강제 지정합니다.
    // 안드로이드: camera 패키지 설정에서 nv21로 요청했으므로 여기서도 nv21로 지정
    // iOS: bgra8888
    final InputImageFormat inputImageFormat = Platform.isAndroid
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;

    // (참고) 만약 iOS에서 색상이 이상하게 나오면 bgra8888 대신 yuv420으로 바꿔보세요.
    // 하지만 대부분 bgra8888이 맞습니다.

    // 4. bytesPerRow 계산 (안드로이드/iOS 차이 처리)
    // 안드로이드는 첫 번째 plane의 rowStride를 사용하는 것이 일반적입니다.
    final planeData = image.planes.first;

    // 간혹 bytesPerRow가 널이거나 0인 경우를 대비해 width로 대체
    final int bytesPerRow = planeData.bytesPerRow;

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
  }
}
