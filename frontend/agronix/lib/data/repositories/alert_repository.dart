import '../../domain/entities/alert_entity.dart';
import '../data_sources/remote/api_client.dart';
import '../models/alert_model.dart';
import '../../services/endpoints/endpoints.dart';

abstract class AlertRepository {
  Future<List<AlertEntity>> getAllAlerts();
  Future<List<AlertEntity>> getUnreadAlerts();
  Future<AlertEntity> getAlertById(int id);
  Future<AlertEntity> markAsRead(int id);
  Future<AlertEntity> dismissAlert(int id);
  Future<void> deleteAlert(int id);
}

class AlertRepositoryImpl implements AlertRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<AlertEntity>> getAllAlerts() async {
    try {
      final response = await _apiClient.get(AlertEndpoints.list);
      final List<dynamic> alertsJson = response as List<dynamic>;
      return alertsJson.map((json) => AlertModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error obteniendo alertas: $e');
    }
  }

  @override
  Future<List<AlertEntity>> getUnreadAlerts() async {
    try {
      final response = await _apiClient.get('${AlertEndpoints.list}?is_read=false');
      final List<dynamic> alertsJson = response as List<dynamic>;
      return alertsJson.map((json) => AlertModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error obteniendo alertas no leídas: $e');
    }
  }

  @override
  Future<AlertEntity> getAlertById(int id) async {
    try {
      final response = await _apiClient.get(AlertEndpoints.detail(id));
      return AlertModel.fromJson(response);
    } catch (e) {
      throw Exception('Error obteniendo alerta: $e');
    }
  }

  @override
  Future<AlertEntity> markAsRead(int id) async {
    try {
      final response = await _apiClient.post(
        AlertEndpoints.acknowledge(id),
        {},
      );
      return AlertModel.fromJson(response);
    } catch (e) {
      throw Exception('Error marcando alerta como leída: $e');
    }
  }

  @override
  Future<AlertEntity> dismissAlert(int id) async {
    try {
      final response = await _apiClient.post(
        AlertEndpoints.dismiss(id),
        {},
      );
      return AlertModel.fromJson(response);
    } catch (e) {
      throw Exception('Error descartando alerta: $e');
    }
  }

  @override
  Future<void> deleteAlert(int id) async {
    try {
      await _apiClient.delete(AlertEndpoints.detail(id));
    } catch (e) {
      throw Exception('Error eliminando alerta: $e');
    }
  }
}
