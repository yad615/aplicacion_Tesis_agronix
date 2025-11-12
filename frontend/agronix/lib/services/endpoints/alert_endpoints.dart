
import '../../config/api_config.dart';

class AlertEndpoints {
  static String get list => '${ApiConfig.baseUrl}/api/alerts/';
  static String get active => '${ApiConfig.baseUrl}/api/alerts/active/';
  
  static String detail(int id) => '${ApiConfig.baseUrl}/api/alerts/$id/';
  static String acknowledge(int id) => '${ApiConfig.baseUrl}/api/alerts/$id/acknowledge/';
  static String dismiss(int id) => '${ApiConfig.baseUrl}/api/alerts/$id/dismiss/';
}
