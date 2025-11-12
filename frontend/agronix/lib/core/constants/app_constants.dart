// lib/core/constants/app_constants.dart

class AppConstants {
  // App Info
  static const String appName = 'AgroNix';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String keyToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserData = 'user_data';
  static const String keySelectedParcela = 'selected_parcela';
  
  // API Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Refresh Intervals
  static const Duration sensorDataRefreshInterval = Duration(minutes: 5);
  static const Duration alertsRefreshInterval = Duration(minutes: 2);
  
  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // Sensor Thresholds
  static const double minTemperatureAir = 20.0;
  static const double maxTemperatureAir = 25.0;
  static const double minHumiditySoil = 35.0;
  static const double maxHumiditySoil = 65.0;
  static const double minConductivity = 0.7;
  static const double maxConductivity = 1.2;
}
