import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:agronix/services/endpoints/user_endpoints.dart';
import 'package:agronix/services/auth_service.dart';
import 'package:agronix/screens/auth_login_screen.dart';
import 'package:agronix/config/api_config.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  
  // Controladores para los campos del formulario
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController nombresController;
  late TextEditingController apellidosController;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true; // Para el indicador de carga inicial
  String? _profileImageUrl;
  
  @override
  void initState() {
    super.initState();
    // Inicializamos los controladores vacíos primero
    usernameController = TextEditingController();
    emailController = TextEditingController();
    nombresController = TextEditingController();
    apellidosController = TextEditingController();
    
    // Llamamos a la función para cargar los datos desde la API
    _loadProfileData();
  }
    Future<void> _pickProfileImage() async {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        // Opcional: subir la imagen al backend aquí
        await _uploadProfileImage(_profileImage!);
      }
    }

    Future<void> _uploadProfileImage(File imageFile) async {
      final token = widget.userData['token'] as String?;
      if (token == null) return;

      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('${ApiConfig.baseUrl}api/user/profile/'),
      );
      request.headers['Authorization'] = 'Token $token';
      request.files.add(await http.MultipartFile.fromPath('imagen', imageFile.path));
      try {
        var response = await request.send();
        if (response.statusCode == 200) {
          final respStr = await response.stream.bytesToString();
          final respJson = json.decode(respStr);
          setState(() {
            _profileImageUrl = respJson['imagen_url'] ?? _profileImageUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagen de perfil actualizada'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al subir imagen (${response.statusCode})'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e'), backgroundColor: Colors.red),
        );
      }
    }

  // Función para CARGAR los datos desde la API
  Future<void> _loadProfileData() async {
    setState(() { _isLoading = true; });

    final token = widget.userData['token'] as String?;
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}api/user/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          setState(() {
            usernameController.text = data['username'] ?? '';
            emailController.text = data['email'] ?? '';
            nombresController.text = data['nombres'] ?? '';
            apellidosController.text = data['apellidos'] ?? '';
            _profileImageUrl = data['imagen_url'] ?? null;
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar perfil: Respuesta no válida (no es JSON)'), backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar perfil: ${response.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar perfil: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // Función para GUARDAR los datos en la API
  Future<void> _saveProfile() async {
    final token = widget.userData['token'] as String?;
    if (token == null) return;

    final Map<String, dynamic> updatedData = {
      'nombres': nombresController.text,
      'apellidos': apellidosController.text,
      // Agrega aquí los demás campos si tienes los controladores
    };

    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}api/user/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode(updatedData),
      );
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar el perfil: Respuesta no válida (no es JSON)'), backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el perfil: ${response.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el perfil: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    nombresController.dispose();
    apellidosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B4D3E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () async {
              if (isEditing) {
                await _saveProfile();
              }
              setState(() {
                isEditing = !isEditing;
              });
            },
            child: Text(
              isEditing ? 'Guardar' : 'Editar',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 30),
                  _buildProfileForm(),
                  const SizedBox(height: 30),
                  _buildProfileStats(),
                  const SizedBox(height: 30),
                  _buildLogoutButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            if (_profileImageUrl != null)
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(_profileImageUrl!),
              )
            else if (_profileImage != null)
              CircleAvatar(
                radius: 60,
                backgroundImage: FileImage(_profileImage!),
              )
            else
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF4A9B8E),
                child: Text(
                  usernameController.text.isNotEmpty ? usernameController.text.substring(0, 1).toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 50, color: Colors.white),
                ),
              ),
            if (isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A9B8E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          usernameController.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Agricultor',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildProfileField(
            'Nombre de Usuario',
            usernameController,
            Icons.person,
            enabled: false,
          ),
          _buildDivider(),
          _buildProfileField(
            'Correo Electrónico',
            emailController,
            Icons.email,
            enabled: false,
          ),
          _buildDivider(),
          _buildProfileField(
            'Nombres',
            nombresController,
            Icons.badge,
            enabled: isEditing,
          ),
          _buildDivider(),
          _buildProfileField(
            'Apellidos',
            apellidosController,
            Icons.badge,
            enabled: isEditing,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(String label, TextEditingController controller,
      IconData icon, {bool enabled = false}) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4A9B8E)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  enabled: enabled,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF2A2A2A), // Fondo oscuro
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
                    hintText: label,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey[700],
      height: 1,
      indent: 56,
    );
  }

  Widget _buildProfileStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Cultivos', '12', Icons.agriculture),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Cosechas', '28', Icons.inventory),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('Días', '156', Icons.calendar_today),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF4A9B8E), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('¿Cerrar Sesión?', style: TextStyle(color: Colors.white)),
              content: const Text('¿Estás seguro de que deseas cerrar sesión?', style: TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await AuthService.logout();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AuthLoginScreen()),
              (route) => false,
            );
          }
        },
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text('Cerrar Sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[700],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}