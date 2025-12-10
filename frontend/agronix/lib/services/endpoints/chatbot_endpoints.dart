import '../../config/api_config.dart';

class ChatbotEndpoints {
  static String get cropData => '${ApiConfig.baseUrl}/api/chatbot/crop-data/';
  static String get chat => '${ApiConfig.baseUrl}/api/chatbot/';
  static String get history => '${ApiConfig.baseUrl}/api/chatbot/history/';
}
