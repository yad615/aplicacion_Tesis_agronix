// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundMain,
      fontFamily: 'Roboto',
      useMaterial3: true,
      
      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        background: AppColors.backgroundMain,
        surface: AppColors.backgroundContent,
        onPrimary: AppColors.textLight,
        onSecondary: AppColors.textLight,
        onBackground: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      
      // Text Theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        bodySmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        labelLarge: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.backgroundContent,
          minimumSize: Size(double.infinity, 56),
          textStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundContent,
        contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.secondary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.secondary, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: TextStyle(
          color: AppColors.secondary,
          fontSize: 18,
        ),
        labelStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.backgroundContent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: AppColors.primary,
        size: 24,
      ),
    );
  }
  
  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: 'Roboto',
      useMaterial3: true,
      
      // Color Scheme
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryLight,
        secondary: AppColors.secondary,
        background: AppColors.backgroundDark,
        surface: AppColors.backgroundCard,
        onPrimary: AppColors.textLight,
        onSecondary: AppColors.textLight,
        onBackground: AppColors.textLight,
        onSurface: AppColors.textLight,
        error: AppColors.error,
      ),
      
      // Text Theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textLight,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textLight,
          fontSize: 18,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textLight,
          fontSize: 16,
        ),
        bodySmall: TextStyle(
          color: AppColors.textGrey,
          fontSize: 14,
        ),
        labelLarge: TextStyle(
          color: AppColors.primaryLight,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.textLight,
          minimumSize: Size(double.infinity, 56),
          textStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundCard,
        contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.textGrey, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.textGrey, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: TextStyle(
          color: AppColors.textGrey,
          fontSize: 18,
        ),
        labelStyle: TextStyle(
          color: AppColors.textLight,
          fontSize: 18,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.backgroundCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: AppColors.primaryLight,
        size: 24,
      ),
    );
  }
}
