import '../../config/api_config.dart';

class ParcelaEndpoints {
  static String get list => '${ApiConfig.baseUrl}/api/parcelas/';
  static String get create => '${ApiConfig.baseUrl}/api/parcelas/';
  
  static String update(int id) => '${ApiConfig.baseUrl}/api/parcelas/$id/';
  static String delete(int id) => '${ApiConfig.baseUrl}/api/parcelas/$id/';
  static String detail(int id) => '${ApiConfig.baseUrl}/api/parcelas/$id/';
  
  // Endpoint para subir imágenes a una parcela
  static String uploadImages(int parcelaId) => '${ApiConfig.baseUrl}/api/parcelas/$parcelaId/images/';
}
