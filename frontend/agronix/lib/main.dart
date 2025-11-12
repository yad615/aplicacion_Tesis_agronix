import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

// Core
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'data/data_sources/local/local_storage.dart';

// Repositories
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/parcela_repository.dart';
import 'data/repositories/task_repository.dart';
import 'data/repositories/alert_repository.dart';

// ViewModels
import 'presentation/view_models/auth_view_model.dart';
import 'presentation/view_models/dashboard_view_model.dart';
import 'presentation/view_models/parcelas_view_model.dart';
import 'presentation/view_models/calendar_view_model.dart';
import 'presentation/view_models/alerts_view_model.dart';

// Views (MVVM)
import 'presentation/views/auth/login_view.dart';

// Screens (temporal hasta migrar a views)
import 'screens/splash_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar LocalStorage
  await LocalStorage().init();
  
  if (kDebugMode) {
    debugPrint('AgroNix App iniciando con arquitectura MVVM...');
  }
  
  runApp(const AgroNixApp());
}

class AgroNixApp extends StatelessWidget {
  const AgroNixApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth ViewModel
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(AuthRepositoryImpl()),
        ),
        // Dashboard ViewModel
        ChangeNotifierProvider(
          create: (_) => DashboardViewModel(
            ParcelaRepositoryImpl(),
            TaskRepositoryImpl(),
            AlertRepositoryImpl(),
          ),
        ),
        // Parcelas ViewModel
        ChangeNotifierProvider(
          create: (_) => ParcelasViewModel(ParcelaRepositoryImpl()),
        ),
        // Calendar ViewModel
        ChangeNotifierProvider(
          create: (_) => CalendarViewModel(TaskRepositoryImpl()),
        ),
        // Alerts ViewModel
        ChangeNotifierProvider(
          create: (_) => AlertsViewModel(AlertRepositoryImpl()),
        ),
      ],
      child: MaterialApp(
        title: 'AgroNix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.login: (context) => const LoginView(),
          AppRoutes.register: (context) => const RegisterScreen(),
          AppRoutes.dashboard: (context) => const DashboardScreen(userData: {}),
          AppRoutes.profile: (context) => const ProfileScreen(userData: {}),
        },
      ),
    );
  }
}