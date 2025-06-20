import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  // Controllers de animación
  late AnimationController _mainAnimationController;
  late AnimationController _backgroundAnimationController;
  
  // Animaciones
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideUpAnimation;
  late Animation<double> _backgroundParallaxAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController, 
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideUpAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController, 
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _backgroundParallaxAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController, 
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimations() {
    _mainAnimationController.forward();
    _backgroundAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      const String apiUrl = 'http://10.0.2.2:8000/auth/login'; 
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': _usernameController.text.trim(), 
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        _showSuccessDialog();
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        _showErrorDialog(responseData['message'] ?? 'Error de autenticación');
      }
    } catch (e) {
      _showErrorDialog('Error de conexión. Verifica tu conexión a internet.');
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('¡Bienvenido!'),
          ],
        ),
        content: const Text('Has iniciado sesión exitosamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1DB584),
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1DB584),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fondo con imagen - ahora ocupa más espacio
          _buildBackgroundImage(),
          
          // Overlay con gradiente sutil
          _buildGradientOverlay(),
          
          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                _buildTopTitle(),
                
                SizedBox(height: MediaQuery.of(context).size.height * 0.12), // Aumentado de 0.08 a 0.12
                
                Expanded(
                  child: _buildLoginCard(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return AnimatedBuilder(
      animation: _backgroundParallaxAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _backgroundParallaxAnimation.value * 15),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.85, // Aumentado de 0.75 a 0.85
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/loginfondo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.85, // Aumentado de 0.75 a 0.85
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.7, 1.0],
          colors: [
            Colors.black.withOpacity(0.1),
            Colors.transparent,
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTitle() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 24.0, top: 20.0, right: 24.0),
        child: const Text(
          'Hello!',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w300,
            color: Colors.white,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                offset: Offset(0, 2),
                blurRadius: 8,
                color: Colors.black26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return SlideTransition(
      position: _slideUpAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 16.0), // Reducido padding vertical de 20 a 16
            child: SingleChildScrollView( // Añadido scroll para evitar overflow
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Título del formulario
                  const Text(
                    'Inicio de sesión',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1DB584),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 16
                  ), // Reducido de 12 a 8 // Reducido de 16 a 12

                  // Campo Usuario
                  const Text(
                    'Usuario:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _usernameController,
                    hintText: 'nombre de usuario',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu nombre de usuario';
                      }
                      if (value.length < 3) {
                        return 'El usuario debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12), // Reducido de 12 a 8

                  // Campo Email
                  const Text(
                    'Email:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'example@gmail.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu correo';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Por favor ingresa un correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12), // Reducido de 12 a 8

                  // Campo Contraseña
                  const Text(
                    'Contraseña:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'aqui contraseña',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF9CA3AF),
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
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
                  const SizedBox(height: 6),

                  // Link "¿Olvidaste tu contraseña?"
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Acción para recuperar contraseña
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botón "acceder"
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DB584),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'acceder',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12), // Reducido de 16 a 12

                  // Texto "entrar con"
                  const Center(
                    child: Text(
                      'entrar con',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Botón de Google
                  Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            // Acción para login con Google
                          },
                          child: Center(
                            child: Image.network(
                              'https://developers.google.com/identity/images/g-logo.png',
                              width: 16,
                              height: 16,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.g_mobiledata,
                                  size: 20,
                                  color: Color(0xFF4285F4),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Link "¿No tienes una cuenta? Regístrate"
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿No tienes cuenta? ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF3B82F6),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Regístrate',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 42, // Reducido de 48 a 42
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(
          fontSize: 14, // Reducido de 15 a 14
          fontWeight: FontWeight.w400,
          color: Color(0xFF374151),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14, // Reducido de 15 a 14
            fontWeight: FontWeight.w400,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10, // Reducido de 12 a 10
          ),
        ),
      ),
    );
  }
}