import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../data_sources/remote/api_client.dart';
import '../data_sources/local/local_storage.dart';
import '../models/user_model.dart';
import '../../services/endpoints/endpoints.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient = ApiClient();
  final LocalStorage _localStorage = LocalStorage();

  @override
  Future<UserEntity> login(String username, String password) async {
    try {
      final response = await _apiClient.post(
        AuthEndpoints.login,
        {'username': username, 'password': password},
        requiresAuth: false,
      );

      final token = response['token'] as String;
      await _localStorage.saveToken(token);

      final userModel = UserModel.fromJson(response['user']);
      await _localStorage.saveUserData(userModel.toJson());

      return userModel;
    } catch (e) {
      throw Exception('Error en login: $e');
    }
  }

  @override
  Future<UserEntity> register(Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.post(
        AuthEndpoints.register,
        userData,
        requiresAuth: false,
      );

      final token = response['token'] as String;
      await _localStorage.saveToken(token);

      final userModel = UserModel.fromJson(response['user']);
      await _localStorage.saveUserData(userModel.toJson());

      return userModel;
    } catch (e) {
      throw Exception('Error en registro: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      final token = _localStorage.getToken();
      if (token != null) {
        await _apiClient.post(AuthEndpoints.logout, {});
      }
    } catch (e) {
      // Continuar con el logout local aunque falle el servidor
    } finally {
      await _localStorage.removeToken();
      await _localStorage.removeUserData();
    }
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    try {
      final userData = _localStorage.getUserData();
      if (userData == null) {
        throw Exception('No hay usuario autenticado');
      }
      return UserModel.fromJson(userData);
    } catch (e) {
      throw Exception('Error obteniendo usuario: $e');
    }
  }

  @override
  Future<UserEntity> updateProfile(Map<String, dynamic> userData) async {
    try {
      final response = await _apiClient.patch(
        AuthEndpoints.userProfile,
        userData,
      );

      final userModel = UserModel.fromJson(response);
      await _localStorage.saveUserData(userModel.toJson());

      return userModel;
    } catch (e) {
      throw Exception('Error actualizando perfil: $e');
    }
  }

  @override
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _apiClient.post(
        '${AuthEndpoints.userProfile}change-password/',
        {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
    } catch (e) {
      throw Exception('Error cambiando contraseña: $e');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = _localStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> getToken() async {
    return _localStorage.getToken();
  }
}
