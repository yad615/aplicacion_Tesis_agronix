// lib/services/auth_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:agronix/models/user_model.dart';
import 'package:agronix/services/endpoints/auth_endpoints.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  // ═══════════════════════════════════════════════════════════════
  // MÉTODOS DE ALMACENAMIENTO LOCAL
  // ═══════════════════════════════════════════════════════════════

  /// Guardar token y datos de usuario localmente
  static Future<void> saveAuthData(String token, UserModel user) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userDataKey, value: jsonEncode(user.toJson()));
  }

  /// Obtener token guardado
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Obtener datos de usuario guardados
  static Future<UserModel?> getUserData() async {
    final userData = await _storage.read(key: _userDataKey);
    if (userData == null) return null;
    return UserModel.fromJson(jsonDecode(userData));
  }

  /// Eliminar todos los datos de autenticación
  static Future<void> clearAuthData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userDataKey);
  }

  /// Verificar si hay sesión activa
  static Future<bool> hasActiveSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ═══════════════════════════════════════════════════════════════
  // LOGIN - VALIDACIÓN CRÍTICA DE ROL
  // ═══════════════════════════════════════════════════════════════

  /// Login con validación obligatoria de role="agricultor"
  /// Retorna AuthResponse solo si el usuario es agricultor
  /// Lanza excepción si el usuario NO es agricultor
  static Future<AuthResponse> login({
    String? username,
    String? email,
    required String password,
  }) async {
    // Validar que se proporcione username O email
    if ((username == null || username.isEmpty) && (email == null || email.isEmpty)) {
      throw Exception('Debe proporcionar un nombre de usuario o email');
    }

    final body = <String, String>{
      'password': password,
    };

    // Enviar username O email (el backend acepta ambos en el campo 'username')
    if (username != null && username.isNotEmpty) {
      body['username'] = username;
    } else if (email != null && email.isNotEmpty) {
      body['username'] = email; // El backend acepta email en el campo username
    }

    final response = await http.post(
      Uri.parse(AuthEndpoints.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));

      // 🚨 VALIDACIÓN CRÍTICA: Solo agricultores pueden acceder a la app móvil
      if (!authResponse.user.isAgricultor) {
        throw AgricultorOnlyException(
          'Esta cuenta no tiene acceso a la aplicación móvil. '
          'Solo los agricultores pueden usar esta aplicación.',
        );
      }

      // ✅ Usuario válido: Guardar credenciales
      await saveAuthData(authResponse.token, authResponse.user);

      return authResponse;
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? error['non_field_errors']?.first ?? 'Credenciales inválidas');
    } else if (response.statusCode == 401) {
      throw Exception('Credenciales incorrectas');
    } else {
      throw Exception('Error de servidor: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // VERIFICACIÓN DE TOKEN Y ROL
  // ═══════════════════════════════════════════════════════════════

  /// Verificar si el token es válido y el usuario es agricultor
  /// Retorna true solo si el token es válido Y el usuario es agricultor
  /// Si el usuario NO es agricultor, elimina la sesión automáticamente solo si forceLogout
  static Future<bool> verifyTokenAndRole({bool forceLogout = true}) async {
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse(AuthEndpoints.verifyToken),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isValid = data['valid'] == true;
        final role = data['role'] as String?;

        // 🚨 VALIDACIÓN: Si el rol no es agricultor, cerrar sesión automáticamente solo si forceLogout
        if (isValid && role != 'agricultor') {
          if (forceLogout) await clearAuthData();
          throw AgricultorOnlyException('Esta cuenta no es de tipo agricultor');
        }

        return isValid && role == 'agricultor';
      } else {
        if (forceLogout) await clearAuthData();
        return false;
      }
    } catch (e) {
      if (forceLogout) await clearAuthData();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // OBTENER PERFIL ACTUAL
  // ═══════════════════════════════════════════════════════════════

  /// Obtener datos actualizados del perfil del usuario
  /// Valida que siga siendo agricultor
  static Future<UserModel> getProfile() async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.get(
      Uri.parse(AuthEndpoints.profile),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final user = UserModel.fromJson(jsonDecode(response.body));

      // 🚨 VALIDACIÓN: Verificar que siga siendo agricultor
      if (!user.isAgricultor) {
        await clearAuthData();
        throw AgricultorOnlyException('Esta cuenta ya no es de tipo agricultor');
      }

      // Actualizar datos guardados localmente
      await _storage.write(key: _userDataKey, value: jsonEncode(user.toJson()));

      return user;
    } else if (response.statusCode == 401) {
      await clearAuthData();
      throw Exception('Sesión expirada');
    } else {
      throw Exception('Error al obtener perfil: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTUALIZAR PERFIL
  // ═══════════════════════════════════════════════════════════════

  /// Actualizar datos del perfil (solo campos editables)
  static Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final body = <String, dynamic>{};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;

    final response = await http.patch(
      Uri.parse(AuthEndpoints.profile),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final user = UserModel.fromJson(jsonDecode(response.body));
      await _storage.write(key: _userDataKey, value: jsonEncode(user.toJson()));
      return user;
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['email']?.first ?? 'Error al actualizar perfil');
    } else if (response.statusCode == 401) {
      await clearAuthData();
      throw Exception('Sesión expirada');
    } else {
      throw Exception('Error al actualizar perfil: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CAMBIAR CONTRASEÑA
  // ═══════════════════════════════════════════════════════════════

  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPassword2,
  }) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final response = await http.post(
      Uri.parse(AuthEndpoints.changePassword),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password2': newPassword2,
      }),
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw Exception(
        error['old_password']?.first ??
            error['new_password']?.first ??
            'Error al cambiar contraseña',
      );
    } else if (response.statusCode == 401) {
      await clearAuthData();
      throw Exception('Sesión expirada');
    } else {
      throw Exception('Error al cambiar contraseña: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SUBIR FOTO DE PERFIL
  // ═══════════════════════════════════════════════════════════════

  static Future<String> uploadProfilePicture(File imageFile) async {
    final token = await getToken();
    if (token == null) throw Exception('No hay sesión activa');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AuthEndpoints.uploadProfilePicture),
    );

    request.headers['Authorization'] = 'Token $token';
    request.files.add(await http.MultipartFile.fromPath('profile_picture', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final profilePictureUrl = data['profile_picture'] as String;

      // Actualizar datos locales
      final user = await getUserData();
      if (user != null) {
        final updatedUser = UserModel(
          id: user.id,
          username: user.username,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          phone: user.phone,
          role: user.role,
          isActive: user.isActive,
          profilePicture: profilePictureUrl,
          dateJoined: user.dateJoined,
          lastLogin: user.lastLogin,
        );
        await _storage.write(key: _userDataKey, value: jsonEncode(updatedUser.toJson()));
      }

      return profilePictureUrl;
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['profile_picture']?.first ?? 'Error al subir imagen');
    } else if (response.statusCode == 401) {
      await clearAuthData();
      throw Exception('Sesión expirada');
    } else {
      throw Exception('Error al subir imagen: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LOGOUT
  // ═══════════════════════════════════════════════════════════════

  static Future<void> logout() async {
    final token = await getToken();
    
    if (token != null) {
      try {
        await http.post(
          Uri.parse(AuthEndpoints.logout),
          headers: {'Authorization': 'Token $token'},
        );
      } catch (e) {
        // Ignorar errores de red, siempre limpiar datos locales
      }
    }

    await clearAuthData();
  }

  // ═══════════════════════════════════════════════════════════════
  // RECUPERACIÓN DE CONTRASEÑA
  // ═══════════════════════════════════════════════════════════════

  static Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse(AuthEndpoints.forgotPassword),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('No existe un usuario con ese email');
    } else {
      throw Exception('Error al enviar código: ${response.statusCode}');
    }
  }

  static Future<void> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
    required String newPassword2,
  }) async {
    final response = await http.post(
      Uri.parse(AuthEndpoints.resetPassword),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'reset_code': resetCode,
        'new_password': newPassword,
        'new_password2': newPassword2,
      }),
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 400) {
      final error = jsonDecode(response.body);
      throw Exception(
        error['error'] ?? error['new_password']?.first ?? 'Error al restablecer contraseña',
      );
    } else {
      throw Exception('Error al restablecer contraseña: ${response.statusCode}');
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// EXCEPCIÓN PERSONALIZADA PARA VALIDACIÓN DE ROL
// ═══════════════════════════════════════════════════════════════

class AgricultorOnlyException implements Exception {
  final String message;
  AgricultorOnlyException(this.message);

  @override
  String toString() => message;
}
