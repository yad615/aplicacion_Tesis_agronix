import '../../config/api_config.dart';

class ChatbotEndpoints {
  static String get cropData => '${ApiConfig.baseUrl}/chatbot/crop-data/';
  static String get chat => '${ApiConfig.baseUrl}/chatbot/chat/';
  static String get history => '${ApiConfig.baseUrl}/chatbot/history/';
}
