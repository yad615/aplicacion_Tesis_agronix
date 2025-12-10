import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:agronix/config/api_config.dart';

class AlertsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AlertsScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> _alertas = [];
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _parcelas = [];
  String? _selectedParcelaId;

  @override
  void initState() {
    super.initState();
    _loadParcelas().then((_) {
      _selectedParcelaId = _parcelas.isNotEmpty
          ? (widget.userData['parcela_id']?.toString() ?? _parcelas.first['id'].toString())
          : null;
      if (_selectedParcelaId != null) {
        widget.userData['parcela_id'] = _selectedParcelaId;
        _loadAlertas();
      }
    });
  }

  Future<void> _loadParcelas() async {
    final userToken = widget.userData['token'];
    if (ApiConfig.baseUrl.isEmpty || userToken == null) {
      setState(() {
        _errorMessage = 'Falta configuración de usuario.';
      });
      return;
    }
    try {
      final url = '${ApiConfig.baseUrl}/api/parcelas/';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $userToken',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parcelasList = (data['results'] ?? data) as List;
        setState(() {
          _parcelas = List<Map<String, dynamic>>.from(parcelasList);
        });
      } else {
        setState(() {
          _errorMessage = 'Error al cargar parcelas (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'No se pudo cargar las parcelas. Verifica tu conexión o vuelve a intentar.';
      });
    }
  }

  Future<void> _loadAlertas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final parcelaId = _selectedParcelaId;
    final userToken = widget.userData['token'];
    if (userToken == null || ApiConfig.baseUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Datos insuficientes: token o baseUrl faltante.';
      });
      return;
    }
    try {
      String url;
      if (parcelaId == null || parcelaId == 'todas') {
        // Mostrar todas las alertas del agricultor
        url = '${ApiConfig.baseUrl}/api/alertas/';
      } else {
        // Mostrar solo las alertas de la parcela seleccionada
        url = '${ApiConfig.baseUrl}/api/parcelas/$parcelaId/alertas/';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $userToken',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final alertasList = (data['results'] ?? data) as List;
        setState(() {
          _alertas = List<Map<String, dynamic>>.from(alertasList);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar alertas (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No se pudo cargar las alertas. Verifica tu conexión o vuelve a intentar.';
      });
    }
  }

  Widget _buildAlertItem(Map<String, dynamic> alerta) {
    final String title = alerta['titulo'] ?? 'Sin datos';
    final String description = alerta['detalle'] ?? alerta['descripcion'] ?? 'Sin datos';
    final String severity = alerta['severity'] ?? 'info';
    final String status = alerta['status'] ?? '';
    final String tipo = alerta['tipo'] ?? '';
    final String createdAt = alerta['created_at'] ?? '';
    final String code = alerta['code'] ?? '';
    final String origen = alerta['origen'] ?? '';

    final icon = _getIconForAlerta(tipo, code, severity);
    final color = _getColorForSeverity(severity);
    final isNew = status == 'new';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF23272A),
        borderRadius: BorderRadius.circular(14),
        border: isNew ? Border.all(color: color.withOpacity(0.5), width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
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
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isNew)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NUEVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (origen == 'ia')
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Automática (IA)', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    if (origen == 'manual')
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Manual', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.grey[500], size: 15),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 14),
                    _buildSeverityChip(severity),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForAlerta(String tipo, String code, String severity) {
    // Puedes personalizar más según code o tipo
    if (code == 'parcela_sin_ciclo') return Icons.warning_amber_rounded;
    if (code == 'parcela_creada') return Icons.add_location_alt_rounded;
    switch (tipo) {
      case 'plaga':
        return Icons.bug_report;
      case 'riego':
        return Icons.water_drop;
      case 'cosecha':
        return Icons.agriculture;
      case 'fertilizacion':
        return Icons.eco;
      case 'clima':
        return Icons.wb_sunny;
      case 'alerta':
        if (severity == 'medium' || severity == 'high') return Icons.warning_amber_rounded;
        return Icons.info_outline_rounded;
      default:
        return Icons.notification_important;
    }
  }

  Color _getColorForSeverity(String severity) {
    switch (severity) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'info':
        return Colors.blueAccent;
      case 'low':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildSeverityChip(String severity) {
    final color = _getColorForSeverity(severity);
    String label = '';
    switch (severity) {
      case 'high':
        label = 'Alta';
        break;
      case 'medium':
        label = 'Media';
        break;
      case 'info':
        label = 'Info';
        break;
      case 'low':
        label = 'Baja';
        break;
      default:
        label = severity;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildOrigenChip(String origen) {
    final isIA = origen == 'ia';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isIA ? Colors.purple : Colors.grey[700],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isIA ? 'Automática (IA)' : 'Manual',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  IconData _getIconForTipo(String? tipo) {
    switch (tipo) {
      case 'plaga':
        return Icons.bug_report;
      case 'riego':
        return Icons.water_drop;
      case 'cosecha':
        return Icons.agriculture;
      case 'fertilizacion':
        return Icons.eco;
      case 'clima':
        return Icons.wb_sunny;
      default:
        return Icons.notification_important;
    }
  }

  Color _getColorForOrigen(String? origen) {
    switch (origen) {
      case 'ia':
        return Colors.purple;
      case 'manual':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

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
          if (_parcelas.isNotEmpty)
            Row(
              children: [
                const Text('Parcela:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedParcelaId,
                    dropdownColor: const Color(0xFF23272A),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF23272A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: 'todas',
                        child: const Text('Todas las parcelas', style: TextStyle(color: Colors.white)),
                      ),
                      ..._parcelas.map((p) => DropdownMenuItem<String>(
                        value: p['id'].toString(),
                        child: Text(p['nombre'] ?? '', style: const TextStyle(color: Colors.white)),
                      ))
                    ],
                    onChanged: (id) {
                      setState(() {
                        _selectedParcelaId = id;
                        widget.userData['parcela_id'] = id;
                      });
                      _loadAlertas();
                    },
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
            )
          else if (_alertas.isEmpty)
            const Text('No hay alertas registradas.', style: TextStyle(color: Colors.white70))
          else
            ..._alertas.map((alerta) => _buildAlertItem(alerta))
        ],
      ),
    );
  }
}