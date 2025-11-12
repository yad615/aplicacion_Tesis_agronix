class ApiConfig {
  static const String baseUrl = 'https://agro-ai-plataform-1.onrender.com';
  static const Duration timeout = Duration(seconds: 30);
  
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Token $token',
  };
}
