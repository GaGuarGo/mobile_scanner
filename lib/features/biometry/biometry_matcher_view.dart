import 'package:cam_scanner_test/features/biometry/controllers/face_camera_controller.dart';
import 'package:cam_scanner_test/features/biometry/controllers/face_matcher_controller.dart';
import 'package:cam_scanner_test/features/biometry/controllers/faces_controller.dart';
import 'package:cam_scanner_test/features/biometry/data/services/face_detection_validation_service.dart';
import 'package:cam_scanner_test/features/biometry/data/services/face_recognition_service.dart';
import 'package:cam_scanner_test/features/biometry/widgets/face_validation_overlay.dart';
import 'package:cam_scanner_test/features/biometry/widgets/saving_face_loading.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BiometryMatcherView extends StatefulWidget {
  const BiometryMatcherView({super.key});

  @override
  State<BiometryMatcherView> createState() => _BiometryMatcherViewState();
}

class _BiometryMatcherViewState extends State<BiometryMatcherView>
    with SingleTickerProviderStateMixin {
  late FaceCameraController _cameraController;
  late FaceRecognitionService _faceRecognitionService;
  late FaceDetectionValidationService _faceDetectionValidationService;

  late FaceMatcherController _faceMatcherController;

  @override
  void initState() {
    _cameraController = FaceCameraController();
    _faceRecognitionService = FaceRecognitionService();
    _faceDetectionValidationService = FaceDetectionValidationService();

    _faceMatcherController = FaceMatcherController(
        tickerProvider: this,
        cameraController: _cameraController,
        faceRecognitionService: _faceRecognitionService,
        faceDetectionValidationService: _faceDetectionValidationService,
        facesController: FacesController());
    super.initState();
  }

  @override
  void dispose() {
    
    super.dispose();
    _faceMatcherController.dispose();  
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: Listenable.merge([
          _faceMatcherController,
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
                  animation: _faceMatcherController.animationController,
                  builder: (context, child) {
                    final ovalWidth = MediaQuery.sizeOf(context).width *
                        _faceMatcherController.overlaySizeAnimation.value;
                    final ovalRect = Rect.fromCenter(
                      center: MediaQuery.sizeOf(context).center(Offset.zero),
                      width: ovalWidth,
                      height: ovalWidth * 1.3,
                    );

                    return CustomPaint(
                      painter: FaceOverlayPainter(
                        borderColor: _faceMatcherController.borderColor,
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
                    _faceMatcherController.feedbackMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_faceMatcherController.savingFace)
                  SavingFaceLoading(
                    message: 'Searching for a match...',
                  ).animate().fadeIn(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      ),
              ],
            ),
          );
        });
  }
}
