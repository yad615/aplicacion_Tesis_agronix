// lib/domain/entities/parcela_entity.dart

class ParcelaEntity {
  final int id;
  final String name;
  final String? description;
  final double area;
  final String location;
  final String cropType;
  final DateTime plantingDate;
  final DateTime? harvestDate;
  final bool isActive;
  final DateTime createdAt;

  ParcelaEntity({
    required this.id,
    required this.name,
    this.description,
    required this.area,
    required this.location,
    required this.cropType,
    required this.plantingDate,
    this.harvestDate,
    required this.isActive,
    required this.createdAt,
  });

  int get daysUntilHarvest {
    if (harvestDate == null) return 0;
    return harvestDate!.difference(DateTime.now()).inDays;
  }

  int get daysFromPlanting {
    return DateTime.now().difference(plantingDate).inDays;
  }
}
