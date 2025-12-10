import '../../config/api_config.dart';

class AuthEndpoints {
  // Autenticación básica
  static String get login => '${ApiConfig.baseUrl}/auth/login/';
  static String get token => '${ApiConfig.baseUrl}/auth/token/';
  static String get register => '${ApiConfig.baseUrl}/api/auth/register/';
  static String get logout => '${ApiConfig.baseUrl}/auth/logout/';
  static String get verifyToken => '${ApiConfig.baseUrl}/api/auth/verify-token/';
  
  // Perfil de usuario
  static String get profile => '${ApiConfig.baseUrl}/api/auth/me/';
  static String get changePassword => '${ApiConfig.baseUrl}/api/auth/change-password/';
  static String get uploadProfilePicture => '${ApiConfig.baseUrl}/api/auth/upload-profile-picture/';
  
  // Recuperación de contraseña
  static String get forgotPassword => '${ApiConfig.baseUrl}/api/auth/forgot-password/';
  static String get resetPassword => '${ApiConfig.baseUrl}/api/auth/reset-password/';
}

