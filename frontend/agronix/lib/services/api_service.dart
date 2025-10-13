// lib/services/api_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000';

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
      Uri.parse('$_baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<void> logout(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/logout/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode != 204) {
      throw Exception('Failed to logout');
    }
  }

  // --- USUARIO ---
  static Future<Map<String, dynamic>> fetchUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/auth/me/'),
      headers: {'Authorization': 'Token $token'},
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateUserProfile(String token, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/auth/me/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }
  
  // --- CROP DATA ---
  static Future<Map<String, dynamic>> getCropData(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/chatbot/crop-data/'), // ✅ URL CORREGIDA
      headers: {'Authorization': 'Token $token'},
    );
    return _handleResponse(response);
  }

  // --- PARCELAS ---
  static Future<Map<String, dynamic>> getParcelas(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/parcelas/'),
      headers: {'Authorization': 'Token $token'},
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createParcela(String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/parcelas/'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateParcela(String token, int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/parcelas/$id/'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Token $token'},
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  static Future<void> deleteParcela(String token, int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/parcelas/$id/'),
      headers: {'Authorization': 'Token $token'},
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
      Uri.parse('$_baseUrl/api/plans/'), // Asumiendo que esta es tu URL de planes
      headers: {'Authorization': 'Token $token'},
    );
    final responseData = _handleResponse(response);
    // Devuelve la lista de planes, que probablemente esté en la clave "results"
    return responseData['results'] ?? responseData;
  }
}