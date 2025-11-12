// lib/data/models/sensor_data_model.dart

import '../../domain/entities/sensor_data_entity.dart';

class SensorDataModel extends SensorDataEntity {
  SensorDataModel({
    required super.id,
    required super.parcelaId,
    required super.temperatureAir,
    required super.humidityAir,
    required super.humiditySoil,
    required super.conductivityEc,
    super.temperatureSoil,
    super.solarRadiation,
    super.pestRisk,
    required super.timestamp,
  });

  factory SensorDataModel.fromJson(Map<String, dynamic> json) {
    return SensorDataModel(
      id: json['id'] as int,
      parcelaId: json['parcela_id'] as int,
      temperatureAir: (json['temperature_air'] as num).toDouble(),
      humidityAir: (json['humidity_air'] as num).toDouble(),
      humiditySoil: (json['humidity_soil'] as num).toDouble(),
      conductivityEc: (json['conductivity_ec'] as num).toDouble(),
      temperatureSoil: json['temperature_soil'] != null
          ? (json['temperature_soil'] as num).toDouble()
          : null,
      solarRadiation: json['solar_radiation'] != null
          ? (json['solar_radiation'] as num).toDouble()
          : null,
      pestRisk: json['pest_risk'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parcela_id': parcelaId,
      'temperature_air': temperatureAir,
      'humidity_air': humidityAir,
      'humidity_soil': humiditySoil,
      'conductivity_ec': conductivityEc,
      'temperature_soil': temperatureSoil,
      'solar_radiation': solarRadiation,
      'pest_risk': pestRisk,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
