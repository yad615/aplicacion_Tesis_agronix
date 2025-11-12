import 'package:flutter/material.dart';
import 'profile_screen.dart'; 
import 'package:agronix/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const SettingsScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool autoIrrigation = false;
  bool darkMode = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuración',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildSettingsSection('Notificaciones', [
            _buildSwitchTile(
              'Notificaciones Push',
              'Recibir alertas y recordatorios',
              notificationsEnabled,
              (value) {
                setState(() {
                  notificationsEnabled = value;
                });
              },
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection('Automatización', [
            _buildSwitchTile(
              'Riego Automático',
              'Activar riego basado en sensores',
              autoIrrigation,
              (value) {
                setState(() {
                  autoIrrigation = value;
                });
              },
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection('Apariencia', [
            _buildSwitchTile(
              'Modo Oscuro',
              'Usar tema oscuro',
              darkMode,
              (value) {
                setState(() {
                  darkMode = value;
                });
              },
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection('Cuenta', [
            _buildActionTile(
              'Perfil de Usuario',
              'Editar información personal',
              Icons.person,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userData: widget.userData),
                ),
              ),
            ),
            _buildActionTile(
              'Cambiar Contraseña',
              'Actualizar contraseña de seguridad',
              Icons.lock,
              () => _showChangePasswordDialog(),
            ),
            _buildActionTile(
              'Cerrar Sesión',
              'Salir de la aplicación',
              Icons.logout,
              () => _showLogoutDialog(),
            ),
          ]),
          const SizedBox(height: 20),
          _buildSettingsSection('Información', [
            _buildActionTile(
              'Acerca de',
              'Versión 1.0.0',
              Icons.info,
              () => _showAboutDialog(),
            ),
            _buildActionTile(
              'Soporte',
              'Contactar soporte técnico',
              Icons.help,
              () => _showSupportDialog(),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[400]),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF4A9B8E),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4A9B8E)),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[400]),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Cambiar Contraseña', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Contraseña actual',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nueva contraseña',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Confirmar nueva contraseña',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contraseña actualizada exitosamente'),
                  backgroundColor: Color(0xFF4A9B8E),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A9B8E)),
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF2A2A2A),
      title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
      content: const Text(
        '¿Estás seguro de que quieres cerrar sesión?',
        style: TextStyle(color: Colors.grey),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () async {
            final String? token = widget.userData['token'];
            if (token == null) return;

            try {
              await ApiService.logout(token);
              Navigator.pop(dialogContext);
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            } catch (e) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error al cerrar sesión. Inténtalo de nuevo.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Cerrar Sesión'),
        ),
      ],
    ),
  );
}


  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('AgroNexus', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Versión: 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aplicación de gestión agrícola inteligente',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Desarrollado por:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Equipo AgroNexus',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A9B8E)),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Soporte Técnico', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contacto:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Email: soporte@agronix.com',
              style: TextStyle(color: Colors.grey),
            ),
            const Text(
              'Teléfono: +51 923190931',
            ),
            const SizedBox(height: 16),
            const Text(
              'Horario de atención:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Lunes a Viernes: 8:00 AM - 6:00 PM',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A9B8E)),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}