// lib/domain/repositories/auth_repository.dart

import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String username, String password);
  Future<UserEntity> register(Map<String, dynamic> userData);
  Future<void> logout();
  Future<UserEntity> getCurrentUser();
  Future<UserEntity> updateProfile(Map<String, dynamic> userData);
  Future<void> changePassword(String oldPassword, String newPassword);
  Future<bool> isLoggedIn();
  Future<String?> getToken();
}
