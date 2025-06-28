import 'dart:io';
import 'dart:math';

import 'package:cam_scanner_test/features/biometry/config/helpers/log_helper.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
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

  static const int _MODEL_INPUT_SIZE = 112;
  static const int _MODEL_OUTPUT_SIZE = 192;

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

  Future<List<double>> getEmbeddingFromStream(
      CameraImage image, Face face) async {
    img.Image? rgbImage = await convertCameraImageToRgb(image);

    if (rgbImage == null) return [];
    img.Image croppedFace = img.copyCrop(
      rgbImage,
      x: face.boundingBox.left.toInt(),
      y: face.boundingBox.top.toInt(),
      width: face.boundingBox.width.toInt(),
      height: face.boundingBox.height.toInt(),
    );

    List<double> embedding = await _preprocessAndRunInference(croppedFace);

    return embedding;
  }

  Future<List<double>> _preprocessAndRunInference(img.Image croppedFace) async {
    final resizedImage = img.copyResize(
      croppedFace,
      width: _MODEL_INPUT_SIZE,
      height: _MODEL_INPUT_SIZE,
    );

    final imageMatrix = List.generate(
      resizedImage.height,
      (y) => List.generate(
        resizedImage.width,
        (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [
            (pixel.r - 127.5) / 127.5,
            (pixel.g - 127.5) / 127.5,
            (pixel.b - 127.5) / 127.5
          ];
        },
      ),
    );

    final input = [imageMatrix];

    final output = List.filled(1 * _MODEL_OUTPUT_SIZE, 0.0)
        .reshape([1, _MODEL_OUTPUT_SIZE]);

    _interpreter.run(input, output);

    final embedding = (output[0] as List<double>);
    return _l2Normalize(embedding);
  }

  Future<img.Image?> convertCameraImageToRgb(CameraImage image) async {
    if (kDebugMode) {
      LogHelper.warning('Camera image format: ${image.format.group}');
      LogHelper.warning('Camera image planes: ${image.planes.length}');
    }

    if (Platform.isAndroid) {
      final data = {
        'width': image.width,
        'height': image.height,
        'planes': image.planes.map((p) => p.bytes).toList(),
      };
      return await compute(_convertNV21toImage, data);
    } else if (Platform.isIOS) {
      // The iOS part remains unchanged.
      final plane = image.planes[0];
      return img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: plane.bytes.buffer,
        order: img.ChannelOrder.bgra,
      );
    }
    return null;
  }

  img.Image _convertNV21toImage(Map<String, dynamic> data) {
    final int width = data['width'];
    final int height = data['height'];
    final List<Uint8List> planes = data['planes'];

    final image = img.Image(width: width, height: height);

    final Uint8List yuvBytes = planes[0];

    final int ySize = width * height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * width + x;

        final int uvIndex = ySize + (y ~/ 2) * width + (x ~/ 2) * 2;

        final int yValue = yuvBytes[yIndex];
        final int vValue = yuvBytes[uvIndex];
        final int uValue = yuvBytes[uvIndex + 1];

        final r = (yValue + 1.402 * (vValue - 128)).toInt();
        final g =
            (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .toInt();
        final b = (yValue + 1.772 * (uValue - 128)).toInt();

        image.setPixelRgb(x, y, r, g, b);
      }
    }
    return image;
  }

  List<double> _l2Normalize(List<double> embedding) {
    final double norm =
        sqrt(embedding.map((val) => val * val).reduce((a, b) => a + b));
    return embedding.map((val) => val / norm).toList();
  }

  double calculateCosineSimilarity(List<double> emb1, List<double> emb2) {
    if (emb1.isEmpty || emb2.isEmpty || emb1.length != emb2.length) {
      return 0.0;
    }

    double dotProduct = 0.0;
    for (int i = 0; i < emb1.length; i++) {
      dotProduct += emb1[i] * emb2[i];
    }
    return dotProduct;
  }

  bool areFacesSimilarCosine(List<double> emb1, List<double> emb2) {
    double similarity = calculateCosineSimilarity(emb1, emb2);

    double threshold = 0.82;

    LogHelper.success("Cosine Similarity: $similarity");
    return similarity > threshold;
  }

  double calculateSquaredEuclideanDistance(
      List<double> emb1, List<double> emb2) {
    if (emb1.isEmpty || emb2.isEmpty || emb1.length != emb2.length) {
      return double.infinity;
    }

    double sumOfSquaredDifferences = 0.0;
    for (int i = 0; i < emb1.length; i++) {
      sumOfSquaredDifferences += pow(emb1[i] - emb2[i], 2);
    }
    return sumOfSquaredDifferences;
  }

  bool areFacesSimilarEuclidean(List<double> emb1, List<double> emb2) {
    double distance = calculateSquaredEuclideanDistance(emb1, emb2);

    double threshold = 1.2;
    double squaredThreshold = threshold * threshold;

    LogHelper.success("Squared Euclidean Distance: $distance");
    return distance < squaredThreshold;
  }
}
