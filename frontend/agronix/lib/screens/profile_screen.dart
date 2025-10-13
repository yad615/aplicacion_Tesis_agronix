import 'package:flutter/material.dart';
import 'package:agronix/services/api_service.dart'; // Importa tu servicio de API

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

  // Función para CARGAR los datos desde la API
  Future<void> _loadProfileData() async {
    setState(() { _isLoading = true; });

    final token = widget.userData['token'] as String?;
    if (token == null) return;

    try {
      final data = await ApiService.fetchUserProfile(token);
      final profile = data['profile'];

      // Rellenamos los controladores con los datos frescos de la API
      setState(() {
        usernameController.text = data['username'] ?? '';
        emailController.text = data['email'] ?? '';
        nombresController.text = profile['nombres'] ?? '';
        apellidosController.text = profile['apellidos'] ?? '';
      });
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

    // Creamos el mapa de datos que espera tu API
    final Map<String, dynamic> updatedData = {
      'nombres': nombresController.text,
      'apellidos': apellidosController.text,
    };

    try {
      // Llamamos al servicio para actualizar el perfil
      await ApiService.updateUserProfile(token, updatedData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
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
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
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