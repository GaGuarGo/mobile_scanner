// ignore_for_file: unnecessary_getters_setters

import 'dart:convert';
import 'dart:io';

import 'package:cam_scanner_test/features/biometry/controllers/face_camera_controller.dart';
import 'package:cam_scanner_test/features/biometry/controllers/faces_controller.dart';
import 'package:cam_scanner_test/features/biometry/data/models/face_model.dart';
import 'package:cam_scanner_test/features/biometry/data/services/database_service.dart';
import 'package:cam_scanner_test/features/biometry/config/enums/biometry_liveness_challange.dart';
import 'package:cam_scanner_test/features/biometry/config/enums/biometry_validation_state.dart';
import 'package:cam_scanner_test/features/biometry/config/helpers/camera_livestream_helper.dart';
import 'package:cam_scanner_test/features/biometry/config/helpers/log_helper.dart';
import 'package:cam_scanner_test/features/biometry/data/services/face_detection_validation_service.dart';
import 'package:cam_scanner_test/features/biometry/data/services/face_recognition_service.dart';
import 'package:cam_scanner_test/navigator_key.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class FaceScannerController extends ChangeNotifier {
  final FaceCameraController _cameraController;
  final TickerProvider _tickerProvider;

  final FaceRecognitionService _faceRecognitionService;
  final DatabaseService _databaseService = DatabaseService();
  final FaceDetectionValidationService _faceDetectionValidationService =
      FaceDetectionValidationService();

  final FacesController _facesController = FacesController();

  FaceScannerController({
    required FaceCameraController cameraController,
    required TickerProvider tickerProvider,
    FaceRecognitionService? faceRecognitionService,
  })  : _cameraController = cameraController,
        _tickerProvider = tickerProvider,
        _faceRecognitionService =
            faceRecognitionService ?? FaceRecognitionService() {
    initialize();
  }

  FaceDetector? _faceDetector;
  FaceDetector get faceDetector => _faceDetector!;

  Face? _userFace;
  Face? get userFace => _userFace;
  set userFace(Face? face) {
    _userFace = face;
  }

  bool _loadingFace = false;
  bool get loadingFace => _loadingFace;
  set loadingFace(bool value) {
    _loadingFace = value;
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

  LivenessChallenge _currentChallenge = LivenessChallenge.initial;
  LivenessChallenge get currentChallenge => _currentChallenge;
  set currentChallenge(LivenessChallenge challenge) {
    _currentChallenge = challenge;
    notifyListeners();
  }

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;
  set isProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  bool _savingFace = false;
  bool get savingFace => _savingFace;
  set savingFace(bool value) {
    _savingFace = value;
    notifyListeners();
  }

  late AnimationController animationController;
  late Animation<double> overlaySizeAnimation;

  @override
  void dispose() {
    super.dispose();
    _faceDetector?.close();
    animationController.dispose();
    _faceDetector = null;
  }

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
    if (isProcessing) return;
    isProcessing = true;

    final inputImage = inputImageFromCameraImage(image,
        controller: _cameraController.cameraController);
    if (inputImage == null) {
      _updateUI(ValidationState.error);
      isProcessing = false;
      return;
    }

    final faces = await faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      _updateUI(ValidationState.noFace);
    }
    // else if (faces.length > 1) {
    //   _updateUI(ValidationState.moreFaces);
    // }
    else {
      await _performChecks(faces.first);
    }

    isProcessing = false;
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
            currentChallenge = LivenessChallenge.turnRight;
          },
        );
        break;
      case LivenessChallenge.turnRight:
        _faceDetectionValidationService.validateTurnHeadRight(
          face: face,
          updateUI: _updateUI,
          nextChallenge: () {
            currentChallenge = LivenessChallenge.turnLeft;
          },
        );
        break;
      case LivenessChallenge.turnLeft:
        _faceDetectionValidationService.validateTurnHeadLeft(
          face: face,
          updateUI: _updateUI,
          nextChallenge: () {
            currentChallenge = LivenessChallenge.getCloser;
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
            currentChallenge = LivenessChallenge.done;
          },
        );
        break;
      case LivenessChallenge.done:
        _updateUI(ValidationState.valid);

        await Future.delayed(500.milliseconds);
        
        await captureFace(face);

        break;
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

      final Directory appDocumentsDir =
          await getApplicationDocumentsDirectory();

      final String fileName =
          'face_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final String permanentPath = join(appDocumentsDir.path, fileName);

      final File permanentImageFile =
          await File(imageFile.path).copy(permanentPath);

      final embedding = await _faceRecognitionService.getEmbedding(
        XFile(permanentImageFile.path),
        face,
      );

      final embeddingJson = jsonEncode(embedding);

      final faceModel = FaceModel(
        embedding: embeddingJson,
        username: "User_${DateTime.now().millisecondsSinceEpoch}",
        photoPath: permanentPath,
      );

      await _databaseService.insertFace(faceModel);
      await _facesController.fetchFaces();

      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Face enrolled successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(navigatorKey.currentContext!).pop(true);
    } catch (e) {
      LogHelper.error("Error during enrollment: $e");

      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
            content: Text('Error during enrollment. Please try again.')),
      );
      Navigator.of(navigatorKey.currentContext!).pop(false);
    } finally {
      savingFace = false;
    }
  }

  void _updateUI(ValidationState state) {
    if (_currentChallenge == LivenessChallenge.initial &&
        state == ValidationState.notLookingStraight) {
      currentChallenge = LivenessChallenge.lookStraight;
    }

    if (state == ValidationState.noFace) {
      animationController.reverse();
    }

    switch (state) {
      case ValidationState.noFace:
        feedbackMessage = "Position your face in the oval";
        borderColor = Colors.white;
        currentChallenge = LivenessChallenge.initial;
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
