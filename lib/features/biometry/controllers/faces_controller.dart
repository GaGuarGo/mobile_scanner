import 'package:cam_scanner_test/features/biometry/config/helpers/log_helper.dart';
import 'package:cam_scanner_test/features/biometry/data/models/face_model.dart';
import 'package:cam_scanner_test/features/biometry/data/services/database_service.dart';
import 'package:cam_scanner_test/navigator_key.dart';
import 'package:flutter/material.dart';

class FacesController extends ChangeNotifier{
  FacesController._();
  static final FacesController _instance = FacesController._();
  factory FacesController() => _instance;

  final DatabaseService _databaseService = DatabaseService();

  List<FaceModel> _faces = [];
  List<FaceModel> get faces => _faces;

  bool _loading = false;
  bool get loading => _loading;
  set loading(bool value) {
    _loading = value;
    notifyListeners();
  }


  Future<void> fetchFaces() async {
    loading = true;
    try {
      _faces = await _databaseService.getFaces();
      _faces.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    } catch (e) {
      LogHelper.error('Error fetching faces: $e');
    } finally {
      loading = false;
    }
  }

  Future<void> deleteFace(FaceModel face) async {
    try {
      await _databaseService.deleteFace(face);
      _faces.remove(face);
      notifyListeners();
    } catch (e) {
      LogHelper.error('Error deleting face: $e');
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Error deleting face'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
