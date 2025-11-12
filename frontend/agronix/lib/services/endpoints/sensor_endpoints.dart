import '../../config/api_config.dart';

class SensorEndpoints {
  static String get readings => '${ApiConfig.baseUrl}/api/sensor-readings/';
  static String get latest => '${ApiConfig.baseUrl}/api/sensor-readings/latest/';
  
  static String parcelaReadings(int parcelaId) => 
      '${ApiConfig.baseUrl}/api/sensor-readings/?parcela=$parcelaId';
  
  static String readingsInRange(int parcelaId, String startDate, String endDate) => 
      '${ApiConfig.baseUrl}/api/sensor-readings/?parcela=$parcelaId&start=$startDate&end=$endDate';
}
