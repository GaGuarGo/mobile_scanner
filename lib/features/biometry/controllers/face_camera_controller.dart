import 'dart:io';
import 'package:cam_scanner_test/features/biometry/config/helpers/log_helper.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class FaceCameraController extends ChangeNotifier {
  FaceCameraController();

  @override
  void dispose() {
    LogHelper.info('FaceCameraController disposed');
    super.dispose();
    _cameraController?.dispose();
  }

  CameraController? _cameraController;
  CameraController get cameraController => _cameraController!;

  bool _isCameraInitialized = false;
  bool get isCameraInitialized => _isCameraInitialized;
  set isCameraInitialized(bool value) {
    _isCameraInitialized = value;
    notifyListeners();
  }

  void initialize(void Function(CameraImage) onAvailable) async {
    if (_cameraController != null) {
      LogHelper.info('CameraController already initialized');
      return;
    }

    LogHelper.info('Initializing FaceCameraController');

    final cameras = await availableCameras();

    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize().then((_) async {
      isCameraInitialized = true;

      await _cameraController!.startImageStream(onAvailable);
    }).catchError((error) {
      LogHelper.error('Error initializing camera: $error');
      _cameraController = null;
      isCameraInitialized = false;
    });
  }
}
