// lib/domain/entities/sensor_data_entity.dart

class SensorDataEntity {
  final int id;
  final int parcelaId;
  final double temperatureAir;
  final double humidityAir;
  final double humiditySoil;
  final double conductivityEc;
  final double? temperatureSoil;
  final double? solarRadiation;
  final String? pestRisk;
  final DateTime timestamp;

  SensorDataEntity({
    required this.id,
    required this.parcelaId,
    required this.temperatureAir,
    required this.humidityAir,
    required this.humiditySoil,
    required this.conductivityEc,
    this.temperatureSoil,
    this.solarRadiation,
    this.pestRisk,
    required this.timestamp,
  });

  // Status helpers
  bool get hasLowSoilHumidity => humiditySoil < 35.0;
  bool get hasHighSoilHumidity => humiditySoil > 65.0;
  bool get hasLowTemperature => temperatureAir < 20.0;
  bool get hasHighTemperature => temperatureAir > 25.0;
  bool get hasLowConductivity => conductivityEc < 0.7;
  bool get hasHighConductivity => conductivityEc > 1.2;
  bool get hasHighPestRisk => pestRisk == 'Alto';
}
