// lib/services/api_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'endpoints/endpoints.dart';

class ApiService {

  // --- MANEJO DE RESPUESTAS (VERSIÓN MEJORADA) ---
  static Map<String, dynamic> _handleResponse(http.Response response) {
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
      Uri.parse(AuthEndpoints.userProfile),
      headers: ApiConfig.authHeaders(token),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateUserProfile(String token, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse(AuthEndpoints.userProfile),
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
    final response = await http.get(
      Uri.parse(PlanEndpoints.list),
      headers: ApiConfig.authHeaders(token),
    );
    final responseData = _handleResponse(response);
    // Devuelve la lista de planes, que probablemente esté en la clave "results"
    return responseData['results'] ?? responseData;
  }
}