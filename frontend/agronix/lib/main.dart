import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart'; 
import 'dashboard_screen.dart';
import 'splash_screen.dart';



void main() {
  runApp(const AgroNixApp());
}

class AgroNixApp extends StatelessWidget {
  const AgroNixApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroNix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: MaterialColor(
          0xFF4A9B8E,
          const <int, Color>{
            50: Color(0xFFE8F5F3),
            100: Color(0xFFC6E6E0),
            200: Color(0xFFA0D5CB),
            300: Color(0xFF7AC4B6),
            400: Color(0xFF5DB7A6),
            500: Color(0xFF4A9B8E),
            600: Color(0xFF429386),
            700: Color(0xFF39897B),
            800: Color(0xFF317F71),
            900: Color(0xFF216D5F),
          },
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A9B8E),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B4D3E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A9B8E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4A9B8E), width: 2),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard':(context) => const DashboardScreen(userData: {},)
      },
    );
  }
}