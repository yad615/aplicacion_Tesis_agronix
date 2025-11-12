import '../../domain/entities/parcela_entity.dart';
import '../data_sources/remote/api_client.dart';
import '../models/parcela_model.dart';
import '../../services/endpoints/endpoints.dart';

abstract class ParcelaRepository {
  Future<List<ParcelaEntity>> getAllParcelas();
  Future<ParcelaEntity> getParcelaById(int id);
  Future<ParcelaEntity> createParcela(Map<String, dynamic> data);
  Future<ParcelaEntity> updateParcela(int id, Map<String, dynamic> data);
  Future<void> deleteParcela(int id);
}

class ParcelaRepositoryImpl implements ParcelaRepository {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<List<ParcelaEntity>> getAllParcelas() async {
    try {
      final response = await _apiClient.get(ParcelaEndpoints.list);
      final List<dynamic> parcelasJson = response as List<dynamic>;
      return parcelasJson.map((json) => ParcelaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error obteniendo parcelas: $e');
    }
  }

  @override
  Future<ParcelaEntity> getParcelaById(int id) async {
    try {
      final response = await _apiClient.get(ParcelaEndpoints.detail(id));
      return ParcelaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error obteniendo parcela: $e');
    }
  }

  @override
  Future<ParcelaEntity> createParcela(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(ParcelaEndpoints.create, data);
      return ParcelaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error creando parcela: $e');
    }
  }

  @override
  Future<ParcelaEntity> updateParcela(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(ParcelaEndpoints.update(id), data);
      return ParcelaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error actualizando parcela: $e');
    }
  }

  @override
  Future<void> deleteParcela(int id) async {
    try {
      await _apiClient.delete(ParcelaEndpoints.delete(id));
    } catch (e) {
      throw Exception('Error eliminando parcela: $e');
    }
  }
}
