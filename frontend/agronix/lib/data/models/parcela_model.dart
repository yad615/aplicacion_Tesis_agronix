// lib/data/models/parcela_model.dart

import '../../domain/entities/parcela_entity.dart';
import 'parcela_image_model.dart';
import 'ciclo_model.dart';

class ParcelaModel extends ParcelaEntity {
  final List<ParcelaImageModel> images;
  final List<CicloModel> ciclos;
  final String? imagenUrl;

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
    this.images = const [],
    this.ciclos = const [],
    this.imagenUrl,
  });

  factory ParcelaModel.fromJson(Map<String, dynamic> json) {
    // Parsear imágenes
    List<ParcelaImageModel> imagesList = [];
    if (json['images'] != null) {
      imagesList = (json['images'] as List)
          .map((img) => ParcelaImageModel.fromJson(img))
          .toList();
    }

    // Parsear ciclos
    List<CicloModel> ciclosList = [];
    if (json['ciclos'] != null) {
      ciclosList = (json['ciclos'] as List)
          .map((ciclo) => CicloModel.fromJson(ciclo))
          .toList();
    }

    // Mapear campos de la API a campos del modelo
    return ParcelaModel(
      id: json['id'] as int,
      name: json['nombre'] as String,
      description: json['ubicacion'] as String?,
      area: double.parse(json['tamano_hectareas']?.toString() ?? '0'),
      location: json['ubicacion'] as String,
      cropType: ciclosList.isNotEmpty ? ciclosList.first.cultivo : 'Sin cultivo',
      plantingDate: ciclosList.isNotEmpty ? ciclosList.first.etapaInicio : DateTime.now(),
      harvestDate: ciclosList.isNotEmpty ? ciclosList.first.fechaCierre : null,
      isActive: ciclosList.isNotEmpty ? (ciclosList.first.estado == 'activo') : true,
      createdAt: DateTime.now(), // La API no devuelve este campo, usar fecha actual
      images: imagesList,
      ciclos: ciclosList,
      imagenUrl: json['imagen_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': name,
      'ubicacion': location,
      'tamano_hectareas': area.toString(),
      'latitud': '0', // Agregar si tienes estos valores
      'longitud': '0',
      'altitud': '0',
      'ciclos': ciclos.map((c) => c.toJson()).toList(),
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
    List<ParcelaImageModel>? images,
    List<CicloModel>? ciclos,
    String? imagenUrl,
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
      images: images ?? this.images,
      ciclos: ciclos ?? this.ciclos,
      imagenUrl: imagenUrl ?? this.imagenUrl,
    );
  }
}
