import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
      final userId = widget.userData['id'].toString();
      if (token == null || userId.isEmpty) return;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.0.233:8000/users/profile/upload_image/$userId/'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('profile_image', imageFile.path));
      try {
        var response = await request.send();
        if (response.statusCode == 200) {
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
        Uri.parse('https://agro-ai-plataform-1.onrender.com/api/user/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          usernameController.text = data['username'] ?? '';
          emailController.text = data['email'] ?? '';
          nombresController.text = data['nombres'] ?? '';
          apellidosController.text = data['apellidos'] ?? '';
        });
        // Si el backend provee una url de imagen, podrías guardarla en una variable para mostrarla con Image.network
        // Ejemplo:
        // _profileImageUrl = data['profile_image_url'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar perfil: ${data['detail'] ?? response.body}'), backgroundColor: Colors.red),
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
    final userId = widget.userData['id'].toString();
    if (token == null || userId.isEmpty) return;

    final Map<String, dynamic> updatedData = {
      'nombres': nombresController.text,
      'apellidos': apellidosController.text,
      // Agrega aquí los demás campos si tienes los controladores
    };

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.233:8000/users/profile/update/$userId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updatedData),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar el perfil: ${data['detail'] ?? response.body}'), backgroundColor: Colors.red),
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
            _profileImage != null
                ? CircleAvatar(
                    radius: 60,
                    backgroundImage: FileImage(_profileImage!),
                  )
                : CircleAvatar(
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
}