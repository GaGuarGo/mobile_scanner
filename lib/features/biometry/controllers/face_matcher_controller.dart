import 'dart:convert';

import 'package:cam_scanner_test/features/biometry/config/enums/biometry_liveness_challange.dart';
import 'package:cam_scanner_test/features/biometry/config/enums/biometry_validation_state.dart';
import 'package:cam_scanner_test/features/biometry/config/helpers/camera_livestream_helper.dart';
import 'package:cam_scanner_test/features/biometry/config/helpers/log_helper.dart';
import 'package:cam_scanner_test/features/biometry/controllers/face_camera_controller.dart';
import 'package:cam_scanner_test/features/biometry/controllers/faces_controller.dart';
import 'package:cam_scanner_test/features/biometry/data/models/face_model.dart';
import 'package:cam_scanner_test/features/biometry/data/services/face_detection_validation_service.dart';
import 'package:cam_scanner_test/features/biometry/data/services/face_recognition_service.dart';
import 'package:cam_scanner_test/navigator_key.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceMatcherController extends ChangeNotifier {
  final TickerProvider _tickerProvider;
  final FaceCameraController _cameraController;

  final FaceDetectionValidationService _faceDetectionValidationService;
  final FaceRecognitionService _faceRecognitionService;

  final FacesController _facesController;

  FaceMatcherController({
    required FaceCameraController cameraController,
    required TickerProvider tickerProvider,
    required FaceDetectionValidationService faceDetectionValidationService,
    required FaceRecognitionService faceRecognitionService,
    required FacesController facesController,
  })  : _cameraController = cameraController,
        _tickerProvider = tickerProvider,
        _faceDetectionValidationService = faceDetectionValidationService,
        _faceRecognitionService = faceRecognitionService,
        _facesController = facesController {
    initialize();
  }

  @override
  void dispose() {
    super.dispose();
    _cameraController.dispose();
    _faceDetector?.close();
    animationController.dispose();
  }

  FaceDetector? _faceDetector;
  FaceDetector get faceDetector => _faceDetector!;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;
  set isProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  String _feedbackMessage = "Position your face in the oval";
  String get feedbackMessage => _feedbackMessage;
  set feedbackMessage(String message) {
    _feedbackMessage = message;
    notifyListeners();
  }

  Color _borderColor = Colors.white;
  Color get borderColor => _borderColor;
  set borderColor(Color color) {
    _borderColor = color;
    notifyListeners();
  }

  bool _savingFace = false;
  bool get savingFace => _savingFace;
  set savingFace(bool value) {
    _savingFace = value;
    notifyListeners();
  }

  LivenessChallenge _currentChallenge = LivenessChallenge.initial;

  late AnimationController animationController;
  late Animation<double> overlaySizeAnimation;

  void initialize() {
    animationController = AnimationController(
      vsync: _tickerProvider,
      duration: const Duration(milliseconds: 300),
    );

    overlaySizeAnimation = Tween<double>(
      begin: 0.8,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    ));

    final options = FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      minFaceSize: 0.1,
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);

    _cameraController.initialize(_processCameraImage);
  }

  void _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    final inputImage = inputImageFromCameraImage(image,
        controller: _cameraController.cameraController);
    if (inputImage == null) {
      _updateUI(ValidationState.error);
      _isProcessing = false;
      return;
    }

    final faces = await faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      _updateUI(ValidationState.noFace);
    } else {
      await _performChecks(faces.first);
    }

    _isProcessing = false;
  }

  Future<void> _performChecks(Face face) async {
    if (!_faceDetectionValidationService.isFaceValid(
      face: face,
      cameraController: _cameraController.cameraController,
      updateUI: _updateUI,
    )) {
      return;
    }

    switch (_currentChallenge) {
      case LivenessChallenge.initial:
      case LivenessChallenge.lookStraight:
        _faceDetectionValidationService.validateLookStraight(
          face: face,
          updateUI: _updateUI,
          nextChallenge: () {
            _currentChallenge = LivenessChallenge.getCloser;
            animationController.forward();
          },
        );
        break;
      case LivenessChallenge.getCloser:
        _faceDetectionValidationService.validateGetCloser(
          face: face,
          cameraController: _cameraController.cameraController,
          updateUI: _updateUI,
          nextChallenge: () {
            _currentChallenge = LivenessChallenge.done;
          },
        );
        break;
      case LivenessChallenge.done:
        _updateUI(ValidationState.valid);

        await captureFace(face);

        break;
      case LivenessChallenge.turnRight:
        throw UnimplementedError();
      case LivenessChallenge.turnLeft:
        throw UnimplementedError();
    }
  }

  Future<void> captureFace(Face face) async {
    if (savingFace) return;
    savingFace = true;
    await Future.delayed(500.milliseconds);

    await _cameraController.cameraController.stopImageStream();

    try {
      final XFile imageFile =
          await _cameraController.cameraController.takePicture();

      final matcherFace = await _faceRecognitionService.getEmbedding(
        imageFile,
        face,
      );

      FaceModel? matchedFace;
      double? matchProbalityPercentage;

      for (final FaceModel face in _facesController.faces) {
        final attemptFace = (jsonDecode(face.embedding!) as List<dynamic>)
            .map((f) => double.parse(f.toString()))
            .toList();

        final matchProbality =
            _faceRecognitionService.calculateCosineSimilarity(matcherFace, attemptFace);

        if (matchProbality > (matchProbalityPercentage ?? 0.0)) {
          matchProbalityPercentage = (matchProbality * 100);
        }

        if (matchProbality > 0.6) {
          matchedFace = face;

          break;
        }
      }

      if (matchedFace == null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text(
                'No matching face found. Please try again, or add a new face. Probability: ${matchProbalityPercentage?.toStringAsFixed(2)}%'),
            backgroundColor: Colors.amberAccent,
          ),
        );

        Navigator.of(navigatorKey.currentContext!).pop(false);
      } else {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text('Face Matached with ${matchedFace.username}! with a probability of ${matchProbalityPercentage?.toStringAsFixed(2)}%'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(navigatorKey.currentContext!).pop(true);
      }
    } catch (e) {
      LogHelper.error("Error matching face: $e");

      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Error matching face. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.of(navigatorKey.currentContext!).pop(false);
    } finally {
      savingFace = false;
    }
  }

  void _updateUI(ValidationState state) {
    if (_currentChallenge == LivenessChallenge.initial &&
        state == ValidationState.notLookingStraight) {
      _currentChallenge = LivenessChallenge.lookStraight;
    }

    if (state == ValidationState.noFace) {
      animationController.reverse();
    }

    switch (state) {
      case ValidationState.noFace:
        feedbackMessage = "Position your face in the oval";
        borderColor = Colors.white;
        _currentChallenge = LivenessChallenge.initial;
        break;
      case ValidationState.notInPosition:
        feedbackMessage = "Center your face in the oval";
        borderColor = Colors.yellow;
        break;
      case ValidationState.notLookingStraight:
        feedbackMessage = "Please look straight ahead";
        borderColor = Colors.cyan;
        break;
      case ValidationState.turnRight:
        feedbackMessage = "Slowly turn your head to the right";
        borderColor = Colors.cyan;
        break;
      case ValidationState.turnLeft:
        feedbackMessage = "Now, slowly turn your head to the left";
        borderColor = Colors.cyan;
        break;
      case ValidationState.getCloser:
        feedbackMessage = "Approach the camera slowly";
        borderColor = Colors.cyan;
        break;
      case ValidationState.valid:
        feedbackMessage = "Perfect! Hold still for a moment.";
        borderColor = Colors.green;
        break;
      case ValidationState.error:
        feedbackMessage = "An error occurred. Please try again.";
        borderColor = Colors.red;
        break;
      // case ValidationState.moreFaces:
      //   feedbackMessage = "More than one face detected. Please try again.";
      //   borderColor = Colors.yellowAccent;
      //   break;
      case ValidationState.eyesClosed:
        feedbackMessage = "Please open your eyes";
        borderColor = Colors.yellow;
        break;
    }
  }
}
