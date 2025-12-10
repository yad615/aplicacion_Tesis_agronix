// lib/data/models/parcela_image_model.dart

class ParcelaImageModel {
  final int id;
  final String imageUrl;
  final String publicId;
  final String filename;
  final int uploadedBy;
  final DateTime createdAt;

  ParcelaImageModel({
    required this.id,
    required this.imageUrl,
    required this.publicId,
    required this.filename,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory ParcelaImageModel.fromJson(Map<String, dynamic> json) {
    return ParcelaImageModel(
      id: json['id'] as int,
      imageUrl: json['image_url'] as String,
      publicId: json['public_id'] as String,
      filename: json['filename'] as String,
      uploadedBy: json['uploaded_by'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'public_id': publicId,
      'filename': filename,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
