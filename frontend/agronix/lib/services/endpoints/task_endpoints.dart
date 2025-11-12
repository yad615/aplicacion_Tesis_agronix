import '../../config/api_config.dart';

class TaskEndpoints {
  static String get list => '${ApiConfig.baseUrl}/api/tasks/';
  static String get create => '${ApiConfig.baseUrl}/api/tasks/';
  static String get suggested => '${ApiConfig.baseUrl}/api/tasks/suggested/';
  
  static String detail(int id) => '${ApiConfig.baseUrl}/api/tasks/$id/';
  static String update(int id) => '${ApiConfig.baseUrl}/api/tasks/$id/';
  static String delete(int id) => '${ApiConfig.baseUrl}/api/tasks/$id/';
  static String complete(int id) => '${ApiConfig.baseUrl}/api/tasks/$id/complete/';
  static String accept(int id) => '${ApiConfig.baseUrl}/api/tasks/$id/accept/';
  static String reject(int id) => '${ApiConfig.baseUrl}/api/tasks/$id/reject/';
}
