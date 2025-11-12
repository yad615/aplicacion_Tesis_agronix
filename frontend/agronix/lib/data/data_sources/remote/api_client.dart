// lib/data/data_sources/remote/api_client.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import '../local/local_storage.dart';

class ApiClient {
  final LocalStorage _localStorage = LocalStorage();

  Future<Map<String, String>> _getHeaders({bool requiresAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = _localStorage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Token $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String endpoint, {bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error en GET request: $e');
    }
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error en POST request: $e');
    }
  }

  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error en PUT request: $e');
    }
  }

  Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await http.patch(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Error en PATCH request: $e');
    }
  }

  Future<void> delete(String endpoint, {bool requiresAuth = true}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await http.delete(url, headers: headers);

      if (response.statusCode != 204 && response.statusCode != 200) {
        final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(responseBody['detail'] ?? 'Error al eliminar');
      }
    } catch (e) {
      throw Exception('Error en DELETE request: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody is List) {
        return {'results': responseBody};
      }
      return responseBody;
    } else {
      final errorMessage = responseBody['detail'] ??
          responseBody['error'] ??
          responseBody.toString();
      throw Exception(errorMessage);
    }
  }
}
