import '../../config/api_config.dart';

class UserEndpoints {
  static String uploadImage(int userId) => '${ApiConfig.baseUrl}/users/profile/upload_image/$userId/';
  static String updateProfile(int userId) => '${ApiConfig.baseUrl}/users/profile/update/$userId/';
}
