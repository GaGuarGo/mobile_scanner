import 'package:cam_scanner_test/features/biometry/data/models/face_model.dart';
import 'package:cam_scanner_test/features/biometry/config/helpers/log_helper.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService _instance = DatabaseService._();
  factory DatabaseService() => _instance;

  late Database? _database;

  Future<void> initialize() async {
    final databasePath = await getDatabasesPath();
    String path = join(databasePath, 'local.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS faces (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            embedding TEXT,
            photo_path TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  Future<List<FaceModel>> getFaces() async {
    try {
      if (_database == null) {
        throw Exception('Database not initialized');
      }

      final List<Map<String, dynamic>> maps = await _database!.query('faces');

      return List.generate(maps.length, (i) {
        return FaceModel.fromMap(maps[i]);
      });
    } on Exception catch (e) {
      LogHelper.error('Error fetching faces: $e');
      rethrow;
    }
  }

  Future<void> insertFace(FaceModel face) async {
    try {
      if (_database == null) {
        throw Exception('Database not initialized');
      }

      await _database!.insert(
        'faces',
        face.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on Exception catch (e) {
      LogHelper.error('Error inserting face: $e');
      rethrow;
    }
  }

  Future<void> deleteFace(FaceModel face) async {
    try {
      if (_database == null) {
        throw Exception('Database not initialized');
      }

      await _database!.delete(
        'faces',
        where: 'id = ?',
        whereArgs: [face.id],
      );
    } on Exception catch (e) {
      LogHelper.error('Error deleting face: $e');
      rethrow;
    }
  }

  Future<void> insertFaceEmbedding(String faceId, String embedding) async {
    try {
      if (_database == null) {
        throw Exception('Database not initialized');
      }

      await _database!.insert(
        'faces_embeddings',
        {'face_id': faceId, 'embedding': embedding},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on Exception catch (e) {
      LogHelper.error('Error inserting face embedding: $e');
      rethrow;
    }
  }
}
