import '../../domain/entities/sensor_data_entity.dart';
import '../data_sources/remote/api_client.dart';
import '../models/sensor_data_model.dart';
import '../../services/endpoints/endpoints.dart';

abstract class SensorRepository {
  Future<List<SensorDataEntity>> getSensorDataByParcela(int parcelaId);
  Future<SensorDataEntity> getLatestSensorData(int parcelaId);
  Future<List<SensorDataEntity>> getSensorDataByDateRange(
    int parcelaId,
    DateTime startDate,
    DateTime endDate,
  );
}

class SensorRepositoryImpl implements SensorRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<SensorDataEntity>> getSensorDataByParcela(int parcelaId) async {
    try {
      final response = await _apiClient.get(SensorEndpoints.parcelaReadings(parcelaId));
      final List<dynamic> dataJson = response as List<dynamic>;
      return dataJson.map((json) => SensorDataModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error obteniendo datos del sensor: $e');
    }
  }

  @override
  Future<SensorDataEntity> getLatestSensorData(int parcelaId) async {
    try {
      final response = await _apiClient.get('${SensorEndpoints.latest}?parcela=$parcelaId');
      return SensorDataModel.fromJson(response);
    } catch (e) {
      throw Exception('Error obteniendo último dato del sensor: $e');
    }
  }

  @override
  Future<List<SensorDataEntity>> getSensorDataByDateRange(
    int parcelaId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final url = SensorEndpoints.readingsInRange(
        parcelaId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      );
      final response = await _apiClient.get(url);
      final List<dynamic> dataJson = response as List<dynamic>;
      return dataJson.map((json) => SensorDataModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error obteniendo datos por rango de fechas: $e');
    }
  }
}
