import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const AlertsScreen({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alertas y Notificaciones',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildAlertItem(
            'Riesgo de plaga detectado',
            'Se ha detectado actividad de plagas en la Parcela A. Revisa inmediatamente.',
            Icons.bug_report,
            Colors.red,
            'Hace 10 min',
            true,
          ),
          _buildAlertItem(
            'Riego programado',
            'Es hora de regar la Parcela B según el cronograma establecido.',
            Icons.water_drop,
            Colors.blue,
            'Hace 30 min',
            true,
          ),
          _buildAlertItem(
            'Cosecha lista',
            'Los cultivos de la Parcela C están listos para la cosecha.',
            Icons.agriculture,
            Colors.green,
            'Hace 1 hora',
            false,
          ),
          _buildAlertItem(
            'Fertilización completada',
            'Se completó la fertilización en la Parcela D.',
            Icons.eco,
            Colors.orange,
            'Hace 2 horas',
            false,
          ),
          _buildAlertItem(
            'Clima favorable',
            'Las condiciones climáticas son óptimas para el crecimiento.',
            Icons.wb_sunny,
            Colors.yellow,
            'Hace 3 horas',
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String title, String description, IconData icon,
      Color color, String time, bool isNew) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: isNew ? Border.all(color: color.withOpacity(0.5)) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NUEVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}