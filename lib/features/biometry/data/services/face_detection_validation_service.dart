import 'package:cam_scanner_test/features/biometry/config/enums/biometry_validation_state.dart';
import 'package:cam_scanner_test/features/biometry/config/helpers/scale_recet_helper.dart';
import 'package:cam_scanner_test/navigator_key.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionValidationService {
  bool isFaceValid({
    required Face face,
    required CameraController cameraController,
    required Function(ValidationState) updateUI,
  }) {
    final Size imageSize = Size(
      cameraController.value.previewSize!.height,
      cameraController.value.previewSize!.width,
    );
    final Size screenSize = MediaQuery.of(navigatorKey.currentContext!).size;
    final Rect faceRect = scaleRect(
        rect: face.boundingBox, imageSize: imageSize, widgetSize: screenSize);
    final double ovalWidth = screenSize.width * 0.8;
    final Rect ovalRect = Rect.fromCenter(
        center: screenSize.center(Offset.zero),
        width: ovalWidth,
        height: ovalWidth * 1.3);

    if (!ovalRect.contains(faceRect.center)) {
      updateUI(ValidationState.notInPosition);
      return false;
    }

    final leftEyeOpen = face.leftEyeOpenProbability ?? 0.0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0.0;
    if (leftEyeOpen < 0.5 || rightEyeOpen < 0.5) {
      updateUI(ValidationState.eyesClosed);
      return false;
    }
    return true;
  }

  void validateLookStraight({
    required Face face,
    required Function(ValidationState) updateUI,
    required void Function() nextChallenge,
  }) {
    updateUI(ValidationState.notLookingStraight);
    final y = face.headEulerAngleY ?? 0.0;
    final z = face.headEulerAngleZ ?? 0.0;

    if (y.abs() < 5 && z.abs() < 5) {
      Future.delayed(const Duration(milliseconds: 500), () {
        nextChallenge();
      });
    }
  }

  void validateTurnHeadRight({
    required Face face,
    required Function(ValidationState) updateUI,
    required void Function() nextChallenge,
  }) {
    final y = face.headEulerAngleY ?? 0.0;
    updateUI(ValidationState.turnRight);

    if (y < -15) {
      Future.delayed(const Duration(milliseconds: 500), () {
        nextChallenge();
      });
    }
  }

  void validateTurnHeadLeft({
    required Face face,
    required Function(ValidationState) updateUI,
    required void Function() nextChallenge,
  }) {
    final y = face.headEulerAngleY ?? 0.0;

    updateUI(ValidationState.turnLeft);
    if (y > 15) {
      Future.delayed(const Duration(milliseconds: 500), () {
        nextChallenge();
      });
    }
  }

  void validateGetCloser({
    required Face face,
    required CameraController cameraController,
    required Function(ValidationState) updateUI,
    required void Function() nextChallenge,
  }) {
    final Size screenSize = MediaQuery.of(navigatorKey.currentContext!).size;
    final Size imageSize = Size(
      cameraController.value.previewSize!.height,
      cameraController.value.previewSize!.width,
    );
    final Rect faceRect = scaleRect(
      rect: face.boundingBox,
      imageSize: imageSize,
      widgetSize: screenSize,
    );

    updateUI(ValidationState.getCloser);

    if (faceRect.width > screenSize.width * 0.65) {
      Future.delayed(const Duration(milliseconds: 1300), () {
        nextChallenge();
      });
    }
  }
}
