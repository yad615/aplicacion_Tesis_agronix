import '../../config/api_config.dart';

class AuthEndpoints {
  static String get login => '${ApiConfig.baseUrl}/auth/login/';
  static String get register => '${ApiConfig.baseUrl}/auth/register/';
  static String get logout => '${ApiConfig.baseUrl}/auth/logout/';
  static String get userProfile => '${ApiConfig.baseUrl}/auth/me/';
}
