// lib/services/api_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'endpoints/endpoints.dart';

class ApiService {
  // --- IMÁGENES DE PARCELA ---
  static Future<List<dynamic>> getParcelaImages(String token, int parcelaId) async {
    final url = '${ApiConfig.baseUrl}/api/parcelas/$parcelaId/images/';
    final response = await http.get(
      Uri.parse(url),
      headers: ApiConfig.authHeaders(token),
    );
    final responseData = _handleResponse(response);
    // Puede ser lista directa o paginada
    return responseData['results'] ?? responseData;
  }

  // --- MANEJO DE RESPUESTAS (VERSIÓN MEJORADA) ---
  static Map<String, dynamic> _handleResponse(http.Response response) {
    // Validar que la respuesta sea JSON antes de decodificar
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      print('⚠️ [API] Respuesta NO ES JSON. Content-Type: $contentType');
      print('⚠️ [API] Status: ${response.statusCode}');
      print('⚠️ [API] Body (primeros 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      
      if (response.statusCode == 404) {
        throw Exception('Endpoint no encontrado (404). Verifica que el endpoint exista en tu backend.');
      }
      throw Exception('El servidor retornó HTML en lugar de JSON. El endpoint puede no existir.');
    }

    try {
      // Usamos utf8.decode para manejar correctamente caracteres especiales como tildes
      final dynamic responseBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Si la API devuelve una lista (ej. en listados no paginados), la envolvemos en un mapa
        if (responseBody is List) {
          return {'results': responseBody};
        }
        return responseBody;
      } else {
        // Imprimimos el error específico que devuelve Django para facilitar la depuración
        print('API Error [${response.statusCode}]: $responseBody');
        
        final errorMessage = responseBody['detail'] ?? 
                             responseBody['error'] ?? 
                             responseBody.toString();
        throw Exception('Error de la API: $errorMessage');
      }
    } catch (e) {
      if (e is FormatException) {
        print('❌ [API] Error al parsear JSON: $e');
        throw Exception('Respuesta inválida del servidor. No es JSON válido.');
      }
      rethrow;
    }
  }

  // --- AUTENTICACIÓN ---
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(AuthEndpoints.login),
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode({'username': username, 'password': password}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(AuthEndpoints.register),
      headers: ApiConfig.defaultHeaders,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<void> logout(String token) async {
    final response = await http.post(
      Uri.parse(AuthEndpoints.logout),
      headers: ApiConfig.authHeaders(token),
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to logout');
    }
  }

  // --- USUARIO ---
  static Future<Map<String, dynamic>> fetchUserProfile(String token) async {
    final response = await http.get(
      Uri.parse(AuthEndpoints.profile),
      headers: ApiConfig.authHeaders(token),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateUserProfile(String token, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse(AuthEndpoints.profile),
      headers: ApiConfig.authHeaders(token),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }
  
  // --- CROP DATA ---
  static Future<Map<String, dynamic>> getCropData(String token) async {
    final response = await http.get(
      Uri.parse(ChatbotEndpoints.cropData),
      headers: ApiConfig.authHeaders(token),
    );
    return _handleResponse(response);
  }

  // --- PARCELAS ---
  static Future<Map<String, dynamic>> getParcelas(String token) async {
    final response = await http.get(
      Uri.parse(ParcelaEndpoints.list),
      headers: ApiConfig.authHeaders(token),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createParcela(String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(ParcelaEndpoints.create),
      headers: ApiConfig.authHeaders(token),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateParcela(String token, int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(ParcelaEndpoints.update(id)),
      headers: ApiConfig.authHeaders(token),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<void> deleteParcela(String token, int id) async {
    final response = await http.delete(
      Uri.parse(ParcelaEndpoints.delete(id)),
      headers: ApiConfig.authHeaders(token),
    );
    if (response.statusCode != 204) {
      final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
      print('API Error al eliminar [${response.statusCode}]: $errorBody');
      throw Exception('Fallo al eliminar la parcela');
    }
  }
  
  // --- PLANES ---
  static Future<List<dynamic>> getPlans(String token) async {
    print('🔍 [API] Obteniendo planes desde: ${PlanEndpoints.list}');
    final response = await http.get(
      Uri.parse(PlanEndpoints.list),
      headers: ApiConfig.authHeaders(token),
    );
    print('📡 [API] Respuesta status: ${response.statusCode}');
    print('📦 [API] Respuesta body: ${response.body}');
    
    final responseData = _handleResponse(response);
    print('✅ [API] Datos procesados: $responseData');
    
    // Devuelve la lista de planes, que probablemente esté en la clave "results"
    final plans = responseData['results'] ?? responseData;
    print('📋 [API] Planes encontrados: ${plans is List ? plans.length : 0}');
    return plans;
  }

  // Obtener plan activo de una parcela
  static Future<Map<String, dynamic>> getPlanActivo(
    String token,
    int parcelaId
  ) async {
    final url = '${ApiConfig.baseUrl}/api/parcelas/$parcelaId/plan-activo/';
    final response = await http.get(
      Uri.parse(url),
      headers: ApiConfig.authHeaders(token),
    );
    return _handleResponse(response);
  }
}