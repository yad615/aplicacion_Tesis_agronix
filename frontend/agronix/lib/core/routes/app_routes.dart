// lib/core/routes/app_routes.dart

class AppRoutes {
  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  
  // Main Routes
  static const String dashboard = '/dashboard';
  static const String statistics = '/statistics';
  static const String parcelas = '/parcelas';
  static const String alerts = '/alerts';
  static const String calendar = '/calendar';
  static const String chatbot = '/chatbot';
  
  // Profile Routes
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  
  // Parcela Routes
  static const String parcelaDetail = '/parcela-detail';
  static const String parcelaCreate = '/parcela-create';
  static const String parcelaEdit = '/parcela-edit';
  
  // Task Routes
  static const String taskDetail = '/task-detail';
  static const String taskCreate = '/task-create';
  static const String taskEdit = '/task-edit';
}
