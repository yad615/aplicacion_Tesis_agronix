// lib/data/models/parcela_model.dart

import '../../domain/entities/parcela_entity.dart';

class ParcelaModel extends ParcelaEntity {
  ParcelaModel({
    required super.id,
    required super.name,
    super.description,
    required super.area,
    required super.location,
    required super.cropType,
    required super.plantingDate,
    super.harvestDate,
    required super.isActive,
    required super.createdAt,
  });

  factory ParcelaModel.fromJson(Map<String, dynamic> json) {
    return ParcelaModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      area: (json['area'] as num).toDouble(),
      location: json['location'] as String,
      cropType: json['crop_type'] as String,
      plantingDate: DateTime.parse(json['planting_date'] as String),
      harvestDate: json['harvest_date'] != null
          ? DateTime.parse(json['harvest_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'area': area,
      'location': location,
      'crop_type': cropType,
      'planting_date': plantingDate.toIso8601String(),
      'harvest_date': harvestDate?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ParcelaModel copyWith({
    int? id,
    String? name,
    String? description,
    double? area,
    String? location,
    String? cropType,
    DateTime? plantingDate,
    DateTime? harvestDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ParcelaModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      area: area ?? this.area,
      location: location ?? this.location,
      cropType: cropType ?? this.cropType,
      plantingDate: plantingDate ?? this.plantingDate,
      harvestDate: harvestDate ?? this.harvestDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
