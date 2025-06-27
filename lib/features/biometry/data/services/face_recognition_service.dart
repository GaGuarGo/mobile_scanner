import 'dart:math';

import 'package:cam_scanner_test/features/biometry/config/helpers/log_helper.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FaceRecognitionService {
  FaceRecognitionService._() {
    LogHelper.info("FaceRecognitionService initialized");
    _loadModel();
  }
  static final FaceRecognitionService _instance = FaceRecognitionService._();
  factory FaceRecognitionService() => _instance;

  late Interpreter _interpreter;
  static const String _modelFile = "assets/models/mobile_face_net.tflite";

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(_modelFile);
    } catch (e) {
      LogHelper.error("Failed to load model: $e");
    }
  }

  List<List<List<num>>> _preprocessImage(img.Image image) {
    final resizedImage = img.copyResize(image, width: 112, height: 112);
    List<List<List<num>>> imageMatrix = List.generate(
      112,
      (y) => List.generate(
        112,
        (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [
            (pixel.r - 127.5) / 127.5,
            (pixel.g - 127.5) / 127.5,
            (pixel.b - 127.5) / 127.5,
          ];
        },
      ),
    );

    return imageMatrix;
  }

  Future<List<double>> getEmbedding(XFile imageFile, Face face) async {
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final faceCrop = img.copyCrop(
      image,
      x: face.boundingBox.left.toInt(),
      y: face.boundingBox.top.toInt(),
      width: face.boundingBox.width.toInt(),
      height: face.boundingBox.height.toInt(),
    );

    final preprocessedImage = _preprocessImage(faceCrop);

    final input = [preprocessedImage];

    final output = List.filled(1 * 192, 0.0).reshape([1, 192]);

    _interpreter.run(input, output);

    return List<double>.from(output[0]);
  }

  double compareEmbeddings(
    List<double> emb1,
    List<double> emb2, {
    double threshold = 0.6,
  }) {
    if (emb1.isEmpty || emb2.isEmpty) return 0.0;

    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < emb1.length; i++) {
      dotProduct += emb1[i] * emb2[i];
      normA += pow(emb1[i], 2);
      normB += pow(emb2[i], 2);
    }

    return (dotProduct / (sqrt(normA) * sqrt(normB))).clamp(-1.0, 1.0);
  }
}
