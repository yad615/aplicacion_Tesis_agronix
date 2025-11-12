import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:agronix/services/endpoints/endpoints.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _openGmailSignup() async {
    const String gmailUrl = 'https://accounts.google.com/signup';
    if (await canLaunchUrl(Uri.parse(gmailUrl))) {
      await launchUrl(Uri.parse(gmailUrl), mode: LaunchMode.externalApplication);
    }
  }
  
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    String email = _emailController.text.trim();
    if (!email.endsWith('@agronix.com')) {
      _showErrorDialog('Solo se permiten emails con dominio @agronix.com');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(AuthEndpoints.register),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'email': email,
          'password': _passwordController.text,
           'first_name':_usernameController.text.trim(), 
        }),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData.containsKey('token')) {
            _showSuccessDialog();
        } else {
            _showErrorDialog(responseData['message'] ?? 'Error desconocido en el registro');
        }
      } else {
        String errorMessage = 'Error en el registro';
        
        if (responseData.containsKey('message')) {
          errorMessage = responseData['message'];
        } else if (responseData.containsKey('error')) {
          errorMessage = responseData['error'];
        } else if (responseData.containsKey('errors')) {
          var errors = responseData['errors'];
          if (errors is Map) {
            List<String> errorMessages = [];
            errors.forEach((key, value) {
              if (value is List) {
                errorMessages.addAll(value.map((e) => e.toString()));
              } else {
                errorMessages.add(value.toString());
              }
            });
            errorMessage = errorMessages.join('\n');
          }
        }
        
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      _showErrorDialog('Error de conexión. Verifica tu conexión a internet y que el servidor esté funcionando.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('¡Registro Exitoso!'),
          ],
        ),
        content: const Text('Tu cuenta ha sido creada exitosamente. Ahora puedes iniciar sesión.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Ir al Login'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/loginfondo.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          'Registrarse',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E8B7B),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Email:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _emailController,
                                    hintText: 'nombre@agronix.com',
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingresa tu correo';
                                      }
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                        return 'Por favor ingresa un correo válido';
                                      }
                                      if (!value.endsWith('@agronix.com')) {
                                        return 'Solo se permiten emails @agronix.com';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nombre de Usuario:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _usernameController,
                                    hintText: 'Escribe tu nombre',
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingresa tu nombre';
                                      }
                                      if (value.length < 3) {
                                        return 'El nombre debe tener al menos 3 caracteres';
                                      }
                                      if (value.length > 50) {
                                        return 'El nombre no puede tener más de 50 caracteres';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Contraseña:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _passwordController,
                                    hintText: 'Escribe tu contraseña',
                                    obscureText: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingresa tu contraseña';
                                      }
                                      if (value.length < 6) {
                                        return 'La contraseña debe tener al menos 6 caracteres';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Confirmar contraseña:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _confirmPasswordController,
                                    hintText: 'Confirma tu contraseña',
                                    obscureText: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor confirma tu contraseña';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Las contraseñas no coinciden';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E8B7B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'registrarse',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'entrar con',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),

                        GestureDetector(
                          onTap: _openGmailSignup,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.email,
                                size: 24,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: RichText(
                            text: const TextSpan(
                              text: '¿Ya tienes una cuenta? ',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Ingresar',
                                  style: TextStyle(
                                    color: Color(0xFF2E8B7B),
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF2A2A2A), // Fondo oscuro
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF4A9B8E)), // Borde verde
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF4A9B8E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF4A9B8E), width: 2),
        ),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400]),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}