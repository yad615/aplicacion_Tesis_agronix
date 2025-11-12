// lib/core/utils/validators.dart

class Validators {
  // Email Validator
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu correo electrónico';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Por favor ingresa un correo válido';
    }
    
    return null;
  }
  
  // Password Validator
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    
    return null;
  }
  
  // Required Field Validator
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa $fieldName';
    }
    return null;
  }
  
  // Phone Validator
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu teléfono';
    }
    
    final phoneRegex = RegExp(r'^\d{9,10}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Por favor ingresa un teléfono válido';
    }
    
    return null;
  }
  
  // Number Validator
  static String? validateNumber(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa un valor';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return 'Por favor ingresa un número válido';
    }
    
    if (min != null && number < min) {
      return 'El valor debe ser mayor o igual a $min';
    }
    
    if (max != null && number > max) {
      return 'El valor debe ser menor o igual a $max';
    }
    
    return null;
  }
}
