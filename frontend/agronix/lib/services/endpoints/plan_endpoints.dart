import '../../config/api_config.dart';

class PlanEndpoints {
  static String get list => '${ApiConfig.baseUrl}/api/plans/';
  static String get current => '${ApiConfig.baseUrl}/api/plans/current/';
  
  static String detail(int id) => '${ApiConfig.baseUrl}/api/plans/$id/';
}
