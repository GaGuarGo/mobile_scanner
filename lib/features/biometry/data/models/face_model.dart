class FaceModel {
  String? id;
  String? embedding;
  String? username;
  String? photoPath;
  DateTime? createdAt;

  FaceModel({
    this.id,
    this.embedding,
    this.username,
    this.photoPath,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'embedding': embedding,
      'username': username,
      'photo_path': photoPath,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory FaceModel.fromMap(Map<String, dynamic> map) {
    return FaceModel(
      id: map['id']?.toString(),
      embedding: map['embedding'],
      username: map['username'],
      photoPath: map['photo_path'],
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }
}
