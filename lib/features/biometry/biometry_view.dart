import 'package:cam_scanner_test/features/biometry/controllers/face_camera_controller.dart';
import 'package:cam_scanner_test/features/biometry/controllers/face_scanner_controller.dart';
import 'package:cam_scanner_test/features/biometry/data/services/face_recognition_service.dart';
import 'package:cam_scanner_test/features/biometry/widgets/face_validation_overlay.dart';
import 'package:cam_scanner_test/features/biometry/widgets/saving_face_loading.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BiometryView extends StatefulWidget {
  const BiometryView({super.key});

  @override
  State<BiometryView> createState() => _BiometryViewState();
}

class _BiometryViewState extends State<BiometryView>
    with SingleTickerProviderStateMixin {
  late FaceScannerController _faceScannerController;
  late FaceCameraController _cameraController;

  late final FaceRecognitionService _faceRecognitionService;

  @override
  void initState() {
    _faceRecognitionService = FaceRecognitionService();

    _cameraController = FaceCameraController();
    _faceScannerController = FaceScannerController(
      cameraController: _cameraController,
      tickerProvider: this,
      faceRecognitionService: _faceRecognitionService,
    );

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _faceScannerController.dispose();
    _cameraController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    return AnimatedBuilder(
        animation: Listenable.merge([
          _faceScannerController,
          _cameraController,
        ]),
        builder: (context, _) {
          if (!_cameraController.isCameraInitialized) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          return Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_cameraController.cameraController),
                AnimatedBuilder(
                  animation: _faceScannerController.animationController,
                  builder: (context, child) {
                    final ovalWidth = screenSize.width *
                        _faceScannerController.overlaySizeAnimation.value;
                    final ovalRect = Rect.fromCenter(
                      center: screenSize.center(Offset.zero),
                      width: ovalWidth,
                      height: ovalWidth * 1.3,
                    );

                    return CustomPaint(
                      painter: FaceOverlayPainter(
                        borderColor: _faceScannerController.borderColor,
                        faceRect: ovalRect,
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 80,
                  left: 20,
                  right: 20,
                  child: Text(
                    _faceScannerController.feedbackMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_faceScannerController.savingFace)
                  SavingFaceLoading().animate().fadeIn(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      ),
              ],
            ),
          );
        });
  }
}
