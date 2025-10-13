import 'package:flutter/material.dart';

class AgronixTheme {
  static const Color backgroundMain = Color(0xFFF1E9DA); // Beige claro
  static const Color backgroundContent = Color(0xFFFCFBF8); // Blanco hueso
  static const Color textMain = Color(0xFF111D15); // Verde muy oscuro/Carbón
  static const Color primary = Color(0xFF1E4835); // Verde oscuro
  static const Color secondary = Color(0xFF317453); // Verde medio

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundMain,
    fontFamily: 'Roboto',
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: textMain,
        fontWeight: FontWeight.bold,
        fontSize: 32,
      ),
      headlineMedium: TextStyle(
        color: textMain,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      bodyLarge: TextStyle(
        color: textMain,
        fontSize: 18,
      ),
      bodyMedium: TextStyle(
        color: textMain,
        fontSize: 16,
      ),
      labelLarge: TextStyle(
        color: primary,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: primary,
      secondary: secondary,
      background: backgroundMain,
      surface: backgroundContent,
      onPrimary: backgroundContent,
      onSecondary: backgroundContent,
      onBackground: textMain,
      onSurface: textMain,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: backgroundContent,
        minimumSize: Size(double.infinity, 56),
        textStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundContent,
      contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: secondary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: secondary, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      hintStyle: TextStyle(
        color: secondary,
        fontSize: 18,
      ),
      labelStyle: TextStyle(
        color: textMain,
        fontSize: 18,
      ),
    ),
  );
}
