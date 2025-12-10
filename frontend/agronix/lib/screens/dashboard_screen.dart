import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'dart:async';

import 'package:agronix/screens/statistics_screen.dart';
import 'package:agronix/screens/alerts_screen.dart';
import 'package:agronix/screens/calendar_screen.dart';
import 'package:agronix/screens/settings_screen.dart';
import 'package:agronix/screens/profile_screen.dart';
import 'package:agronix/screens/chatbot_screen.dart';
import 'package:agronix/screens/parcelas_screen.dart';
import 'package:agronix/widgets/dashboard_widgets.dart';
import 'package:agronix/config/api_config.dart';
import 'package:agronix/widgets/sensor_chart_widget.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({super.key, required this.userData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
      @override
      void initState() {
        super.initState();
        _animationController = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 800),
        );
        _fadeAnimation = CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeIn,
        );
        _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
        _animationController.forward();
        _fetchParcelasAndLoadData();
      }

  Future<void> _fetchParcelasAndLoadData() async {
    final String? userToken = widget.userData['token'] as String?;
    if (userToken == null) return;
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/parcelas/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $userToken',
        },
      );
      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);
        final List<dynamic> parcelas = responseJson is List
            ? responseJson
            : (responseJson['results'] ?? []);
        setState(() {
          _parcelas = parcelas.map((p) => {
            'id': p['id'],
            'nombre': p['nombre'],
          }).toList();
        });
        if (_parcelas.isEmpty) {
          setState(() {
            _isLoading = false;
            _lastUpdateMessage = 'No se encontraron parcelas.';
          });
          return;
        }
      } else {
        setState(() {
          _isLoading = false;
          _lastUpdateMessage = 'Error al obtener parcelas.';
        });
        return;
      }
    } catch (e) {
      debugPrint('Error al obtener parcelas en dashboard: $e');
      setState(() {
        _isLoading = false;
        _lastUpdateMessage = 'Error al obtener parcelas.';
      });
      return;
    }
    await _loadInitialData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
    List<Map<String, dynamic>> _parcelas = [];
    int? _selectedParcelaId;
    String? _selectedParcelaNombre;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  int _selectedIndex = 0;

  // Datos del cultivo que se cargarán del backend
  Map<String, dynamic>? _cropData;
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _nodosSensores = [];

    // Series de sensores (últimas 24h, por hora)
    Map<String, List<Map<String, dynamic>>> _sensorSeries = {};

  bool _isLoading = true;
  String _lastUpdateMessage = 'Cargando datos...';

  // ...existing code...

  // Método corregido para cargar datos
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _lastUpdateMessage = 'Cargando datos de sensores...';
    });

    // Usar la parcela seleccionada
    int? parcelaId = _selectedParcelaId ?? widget.userData['parcela_id'];
    if (parcelaId == null && _parcelas.isNotEmpty) {
      parcelaId = _parcelas[0]['id'];
      _selectedParcelaId = parcelaId;
      _selectedParcelaNombre = _parcelas[0]['nombre'];
      widget.userData['parcela_id'] = parcelaId;
      widget.userData['parcela_nombre'] = _selectedParcelaNombre;
    }

    final String? userToken = widget.userData['token'] as String?;
    if (userToken == null || userToken.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _lastUpdateMessage = 'Error: No autenticado.';
      });
      return;
    }

    // Obtener parcela_id solo si aún no está definido
    if (parcelaId == null) {
      parcelaId = await _obtenerPrimeraParcelaId();
      if (parcelaId == null) {
        setState(() {
          _isLoading = false;
          _lastUpdateMessage = 'No se encontraron parcelas.';
        });
        return;
      }
      widget.userData['parcela_id'] = parcelaId;
    }

    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/api/brain/nodes/latest/?parcela=$parcelaId'
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $userToken', // ← Token NO Bearer
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        _procesarDatosSensores(responseData);
        setState(() {
          _lastUpdateMessage = 'Última actualización: ${
            DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())
          }';
          _isLoading = false;
        });

          // Cargar series de sensores (últimas 24h, por hora)
          await _loadSensorSeries(parcelaId, userToken);
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _lastUpdateMessage = 'Sesión expirada.';
        });
        // TODO: Navegar a login
      } else {
        debugPrint('Error HTTP: ${response.statusCode}');
        setState(() {
          _isLoading = false;
          _lastUpdateMessage = 'Error al obtener datos reales del backend.';
        });
      }
    } catch (e) {
      debugPrint('Excepción: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _lastUpdateMessage = 'Error al obtener datos reales del backend.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<int?> _obtenerPrimeraParcelaId() async {
    final String? userToken = widget.userData['token'] as String?;
    if (userToken == null) return null;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/parcelas/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $userToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> parcelas = json.decode(response.body);
        if (parcelas.isNotEmpty) {
          final id = parcelas[0]['id'] as int;
          widget.userData['parcela_id'] = id;
          widget.userData['parcela_nombre'] = parcelas[0]['nombre'];
          return id;
        }
      }
    } catch (e) {
      debugPrint('Error al obtener parcela_id: $e');
    }
    return null;
  }

  void _procesarDatosSensores(Map<String, dynamic> responseData) {
    final List<dynamic> nodos = responseData['nodos'] ?? [];

    if (nodos.isEmpty) {
      setState(() {
        _isLoading = false;
        _lastUpdateMessage = 'No hay datos reales disponibles.';
        _cropData = null;
        _nodosSensores = [];
      });
      return;
    }

    // Guardar nodos y sensores para mostrar dinámicamente
    List<Map<String, dynamic>> nodosSensores = [];
    for (var nodo in nodos) {
      nodosSensores.add({
        'nombre': nodo['nombre'] ?? 'Nodo',
        'activo': nodo['activo'] ?? false,
        'sensores': nodo['sensores'] ?? {},
      });
    }

    double totalTemp = 0.0, totalHumedadAire = 0.0;
    double totalCE = 0.0, totalPH = 0.0;
    int countTemp = 0, countHumedadAire = 0, countCE = 0, countPH = 0;

    for (var nodo in nodos) {
      if (nodo['activo'] == true) {
        final Map<String, dynamic> sensores = nodo['sensores'] ?? {};

        if (sensores.containsKey('temperatura')) {
          totalTemp += (sensores['temperatura'] as num).toDouble();
          countTemp++;
        }
        if (sensores.containsKey('humedad_aire')) {
          totalHumedadAire += (sensores['humedad_aire'] as num).toDouble();
          countHumedadAire++;
        }
        if (sensores.containsKey('ce')) {
          totalCE += (sensores['ce'] as num).toDouble();
          countCE++;
        }
        if (sensores.containsKey('ph')) {
          totalPH += (sensores['ph'] as num).toDouble();
          countPH++;
        }
      }
    }

    final double avgTemp = countTemp > 0 ? totalTemp / countTemp : 22.0;
    final double avgHumedadAire = countHumedadAire > 0 ? totalHumedadAire / countHumedadAire : 65.0;
    final double avgCE = countCE > 0 ? totalCE / countCE : 1.0;

    setState(() {
      _cropData = {
        'temperature_air': double.parse(avgTemp.toStringAsFixed(1)),
        'humidity_air': double.parse(avgHumedadAire.toStringAsFixed(1)),
        'humidity_soil': double.parse(avgHumedadAire.toStringAsFixed(1)),
        'conductivity_ec': double.parse(avgCE.toStringAsFixed(2)),
        'temperature_soil': double.parse((avgTemp - 5).toStringAsFixed(1)),
        'solar_radiation': 500.0,
        'pest_risk': _calcularRiesgoPlagas(avgTemp, avgHumedadAire),
        'last_updated': DateTime.now(),
        'nodos_activos': nodos.where((n) => n['activo'] == true).length,
        'nodos_totales': nodos.length,
      };
      _nodosSensores = nodosSensores;
      _updateAlertsBasedOnData();
    });
  }

  String _calcularRiesgoPlagas(double temp, double humedad) {
    if (temp > 25 && humedad > 70) return 'Alto';
    if (temp > 22 && humedad > 60) return 'Moderado';
    return 'Bajo';
  }


  void _updateAlertsBasedOnData() {
    if (_cropData == null) return; 

    List<Map<String, dynamic>> newAlerts = [];

    if (_cropData!['temperature_air'] < 20.0) {
      newAlerts.add({
        'message': '⚠️ Temperatura del aire baja: ${_cropData!['temperature_air']}°C',
        'type': 'warning', 'color': Colors.blue, 'icon': Icons.thermostat, 'isNew': true
      });
    } else if (_cropData!['temperature_air'] > 25.0) {
      newAlerts.add({
        'message': '🔥 Temperatura del aire alta: ${_cropData!['temperature_air']}°C',
        'type': 'warning', 'color': Colors.red, 'icon': Icons.thermostat, 'isNew': true
      });
    }

    if (_cropData!['humidity_soil'] < 35.0) {
      newAlerts.add({
        'message': '💧 Humedad del suelo baja: ${_cropData!['humidity_soil']}%',
        'type': 'critical', 'color': Colors.orange, 'icon': Icons.water_drop, 'isNew': true
      });
    } else if (_cropData!['humidity_soil'] > 65.0) {
      newAlerts.add({
        'message': '🌊 Humedad del suelo alta: ${_cropData!['humidity_soil']}%',
        'type': 'warning', 'color': Colors.blue, 'icon': Icons.water_drop, 'isNew': true
      });
    }

    if (_cropData!['conductivity_ec'] < 0.7) {
      newAlerts.add({
        'message': '⚡ Conductividad baja: ${_cropData!['conductivity_ec']} dS/m',
        'type': 'recommendation', 'color': const Color(0xFF4A9B8E), 'icon': Icons.bolt, 'isNew': true
      });
    } else if (_cropData!['conductivity_ec'] > 1.2) {
      newAlerts.add({
        'message': '⚡ Conductividad alta: ${_cropData!['conductivity_ec']} dS/m',
        'type': 'warning', 'color': Colors.red, 'icon': Icons.bolt, 'isNew': true
      });
    }

    if (_cropData!['pest_risk'] == 'Alto') {
      newAlerts.add({
        'message': '🐛 Riesgo de plagas alto - Inspección necesaria',
        'type': 'critical', 'color': Colors.red, 'icon': Icons.bug_report, 'isNew': true
      });
    } else if (_cropData!['pest_risk'] == 'Moderado') {
      newAlerts.add({
        'message': '🕷️ Riesgo de plagas moderado - Monitoreo recomendado',
        'type': 'warning', 'color': Colors.orange, 'icon': Icons.bug_report, 'isNew': true
      });
    }

    // Alertas de nodos
    if (_cropData!.containsKey('nodos_activos') &&
        _cropData!.containsKey('nodos_totales')) {
      final int activos = _cropData!['nodos_activos'];
      final int totales = _cropData!['nodos_totales'];

      if (activos == 0) {
        newAlerts.add({
          'message': '⚠️ Todos los nodos están desconectados - Revisar urgente',
          'type': 'critical',
          'color': Colors.red,
          'icon': Icons.sensors_off,
          'isNew': true
        });
      } else if (activos < totales) {
        newAlerts.add({
          'message': '📡 ${totales - activos} nodo(s) inactivo(s) - Verificar conexión',
          'type': 'warning',
          'color': Colors.orange,
          'icon': Icons.wifi_off,
          'isNew': true
        });
      }
    }

    newAlerts.add({
      'message': '📅 Cosecha programada mañana 8:00 a.m.',
      'type': 'schedule', 'color': Colors.blue, 'icon': Icons.calendar_today, 'isNew': false
    });

    setState(() {
      _alerts = newAlerts;
    });
  }

  String _getParameterStatus(String parameter, double value) {
    switch (parameter) {
      case 'temperature_air':
        if (value < 20.0) return 'Bajo';
        if (value > 25.0) return 'Alto';
        return 'Óptimo';
      case 'humidity_air':
        if (value < 60.0) return 'Bajo';
        if (value > 80.0) return 'Alto';
        return 'Óptimo';
      case 'humidity_soil':
        if (value < 35.0) return 'Bajo';
        if (value > 65.0) return 'Alto';
        return 'Óptimo';
      case 'conductivity_ec':
        if (value < 0.7) return 'Bajo';
        if (value > 1.2) return 'Alto';
        return 'Óptimo';
      case 'solar_radiation':
        if (value < 300.0) return 'Bajo';
        if (value > 800.0) return 'Alto';
        return 'Óptimo';
      case 'pest_risk':
        return value.toString();
      default:
        return 'Normal';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Óptimo':
        return const Color(0xFF4A9B8E);
      case 'Alto':
      case 'Alto (Crítico: Inhibición floral)':
        return Colors.red;
      case 'Bajo':
      case 'Bajo (Crítico: Riesgo de heladas)':
        return Colors.orange;
      case 'Moderado':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            // **CORRECCIÓN PRINCIPAL APLICADA AQUÍ**
            // Se usa IndexedStack para mostrar la pantalla correcta y mantener el estado
            // de las otras pantallas al navegar entre ellas.
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: <Widget>[
                  _buildDashboardContent(),
                  StatisticsScreen(userData: widget.userData),
                  ParcelasScreen(userData: widget.userData),
                  AlertsScreen(userData: widget.userData),
                  CalendarScreen(userData: widget.userData),
                  SettingsScreen(userData: widget.userData),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B4D3E),
            Color(0xFF2D5A4A),
            Color(0xFF4A9B8E),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, ${widget.userData['username'] ?? 'Usuario'}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('dd MMMM HH:mm').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Eliminado selector de parcela del header. Ahora solo aparece abajo en el dashboard.
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Column(
                children: [
                  // Selector de parcela (visual, claro, fuera del header)
                  if (_parcelas.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.landscape, color: Color(0xFF4A9B8E)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<int>(
                              value: _selectedParcelaId,
                              dropdownColor: const Color(0xFF2A2A2A),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                              isExpanded: true,
                              items: _parcelas.map((parcela) {
                                return DropdownMenuItem<int>(
                                  value: parcela['id'],
                                  child: Text(parcela['nombre'] ?? 'Parcela'),
                                );
                              }).toList(),
                              onChanged: (int? newId) async {
                                if (newId == null) return;
                                final selected = _parcelas.firstWhere((p) => p['id'] == newId);
                                setState(() {
                                  _selectedParcelaId = newId;
                                  _selectedParcelaNombre = selected['nombre'];
                                  widget.userData['parcela_id'] = newId;
                                  widget.userData['parcela_nombre'] = selected['nombre'];
                                });
                                await _loadInitialData();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_parcelas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white70),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No se encontraron parcelas. Crea una para comenzar.',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Solo mostrar datos si hay parcela seleccionada
                  if (_selectedParcelaId != null)
                    ...[
                      _buildLastUpdate(),
                      const SizedBox(height: 20),
                      _isLoading ? _buildLoadingCards() : _buildCropStatusCards(),
                      const SizedBox(height: 20),
                      _buildAlertsSection(),
                      const SizedBox(height: 20),
                      _buildQuickActions(),
                      const SizedBox(height: 80),
                    ],
                ],
              )
              );
          },
        ),
      ),
    );
  }

  Widget _buildLastUpdate() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isLoading ? Icons.refresh : Icons.check_circle,
            color: _isLoading ? Colors.grey : const Color(0xFF4A9B8E),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _isLoading 
            ? 'Cargando datos...'
            : _lastUpdateMessage,
            style: TextStyle(
              color: _isLoading ? Colors.grey : const Color(0xFF4A9B8E),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildLoadingCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildLoadingCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildLoadingCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildLoadingCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9B8E)),
            strokeWidth: 2,
          ),
          SizedBox(height: 8),
          Text(
            'Cargando...',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCropStatusCards() {
    if (_nodosSensores.isEmpty) {
      return const SizedBox.shrink();
    }
    // Mostrar nodos que tengan datos en cualquier sensor relevante
    final nodosConDatos = _nodosSensores.where((nodo) {
      final sensores = nodo['sensores'] as Map<String, dynamic>;
      final tieneTemp = sensores.containsKey('temperatura') && sensores['temperatura'] != null;
      final tieneHumedadAire = sensores.containsKey('humedad_aire') && sensores['humedad_aire'] != null;
      final tieneHumedadSuelo = sensores.containsKey('humedad_suelo') && sensores['humedad_suelo'] != null;
      return tieneTemp || tieneHumedadAire || tieneHumedadSuelo;
    }).toList();
    if (nodosConDatos.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        ...nodosConDatos.map((nodo) {
          final sensores = nodo['sensores'] as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF23272A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: nodo['activo'] ? const Color(0xFF4A9B8E) : Colors.red,
                width: 1.2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (sensores.containsKey('temperatura') && sensores['temperatura'] != null) ...[
                          Row(
                            children: [
                              Icon(Icons.thermostat, color: Colors.grey[400], size: 18),
                              const SizedBox(width: 6),
                              Text('Temperatura', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${sensores['temperatura']}°C',
                            style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[700]?.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getParameterStatus('temperature_air', (sensores['temperatura'] as num).toDouble()),
                              style: TextStyle(
                                color: _getStatusColor(_getParameterStatus('temperature_air', (sensores['temperatura'] as num).toDouble())),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (sensores.containsKey('humedad_aire') && sensores['humedad_aire'] != null) ...[
                          Row(
                            children: [
                              Icon(Icons.water_drop, color: Colors.grey[400], size: 18),
                              const SizedBox(width: 6),
                              Text('Humedad Aire', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${sensores['humedad_aire']}%',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_getParameterStatus('humidity_air', (sensores['humedad_aire'] as num).toDouble())).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getParameterStatus('humidity_air', (sensores['humedad_aire'] as num).toDouble()),
                              style: TextStyle(
                                color: _getStatusColor(_getParameterStatus('humidity_air', (sensores['humedad_aire'] as num).toDouble())),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (sensores.containsKey('humedad_suelo') && sensores['humedad_suelo'] != null) ...[
                          Row(
                            children: [
                              Icon(Icons.grass, color: Colors.green, size: 18),
                              const SizedBox(width: 6),
                              Text('Humedad Suelo', style: TextStyle(color: Colors.green, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${sensores['humedad_suelo']}%',
                            style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getParameterStatus('humidity_soil', (sensores['humedad_suelo'] as num).toDouble()),
                              style: TextStyle(
                                color: _getStatusColor(_getParameterStatus('humidity_soil', (sensores['humedad_suelo'] as num).toDouble())),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

    // Consulta series de sensores (últimas 24h, por hora)
    Future<void> _loadSensorSeries(int parcelaId, String userToken) async {
      final parametros = ['temperatura', 'humedad_aire', 'humedad_suelo'];
      final period = 'hour';
      final interval = '1';
      final end = DateTime.now();
      final start = end.subtract(const Duration(hours: 24));
      final startStr = DateFormat('yyyy-MM-dd').format(start);
      final endStr = DateFormat('yyyy-MM-dd').format(end);

      Map<String, List<Map<String, dynamic>>> series = {};
      for (final parametro in parametros) {
        final url = '${ApiConfig.baseUrl}/api/brain/series/?parcela=$parcelaId&parametro=$parametro&period=$period&interval=$interval&start=$startStr&end=$endStr';
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $userToken',
            },
          );
          if (response.statusCode == 200) {
            final respJson = json.decode(response.body);
            if (respJson is Map<String, dynamic> && respJson.containsKey('points')) {
              series[parametro] = List<Map<String, dynamic>>.from(respJson['points']);
            } else if (respJson is List) {
              series[parametro] = List<Map<String, dynamic>>.from(respJson);
            } else {
              series[parametro] = [];
            }
          } else {
            series[parametro] = [];
          }
        } catch (e) {
          series[parametro] = [];
        }
      }
      setState(() {
        _sensorSeries = series;
      });
    }

    // Widget para mostrar series de sensores
      // Widget para mostrar nodos y sensores dinámicamente
      Widget _buildNodosSensoresSection() {
    if (_nodosSensores.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.sensors, color: Color(0xFF4A9B8E), size: 22),
            const SizedBox(width: 8),
            const Text('Sensores por Nodo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ..._nodosSensores.map((nodo) {
          final sensores = nodo['sensores'] as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF23272A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: nodo['activo'] ? const Color(0xFF4A9B8E) : Colors.red,
                width: 1.2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: nodo['activo'] ? const Color(0xFF4A9B8E) : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          nodo['activo'] ? Icons.sensors : Icons.sensors_off,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          nodo['nombre'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: nodo['activo'] ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          nodo['activo'] ? 'Activo' : 'Inactivo',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sensores.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A9B8E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                _getSensorLabel(entry.key),
                                style: const TextStyle(color: Color(0xFF4A9B8E), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${entry.value}',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
  // Etiquetas bonitas para sensores
  String _getSensorLabel(String key) {
    switch (key) {
      case 'temperatura':
        return '🌡️ Temperatura';
      case 'humedad_aire':
        return '💧 Humedad Aire';
      case 'humedad_suelo':
        return '🌱 Humedad Suelo';
      case 'ce':
        return '⚡ Conductividad';
      case 'ph':
        return '🧪 pH';
      default:
        return key;
    }
  }

  String _getParametroLabel(String parametro) {
    switch (parametro) {
      case 'temperatura':
        return '🌡️ Temperatura';
      case 'humedad_aire':
        return '💧 Humedad Aire';
      case 'humedad_suelo':
        return '🌱 Humedad Suelo';
      default:
        return parametro;
    }
  }

  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Alertas y Recomendaciones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 3; 
                });
              },
              child: const Text(
                'Ver todas',
                style: TextStyle(color: Color(0xFF4A9B8E)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_alerts.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No hay alertas ni recomendaciones actuales. ¡Tu cultivo está en óptimas condiciones!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ),
        ..._alerts.take(3).map((alert) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: DashboardWidgets.buildAlertCard(
            alert['message'],
            alert['color'],
            alert['icon'],
          ),
        )),
      ],
    );
  }

  void _showActionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Registrar Acción',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
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
                hintText: 'Escribe aquí...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tipo de acción',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'riego', child: Text('Riego')),
                DropdownMenuItem(value: 'fertilizacion', child: Text('Fertilización')),
                DropdownMenuItem(value: 'poda', child: Text('Poda')),
                DropdownMenuItem(value: 'cosecha', child: Text('Cosecha')),
              ],
              onChanged: (value) {},
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
                  content: Text('Acción registrada exitosamente'),
                  backgroundColor: Color(0xFF4A9B8E),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9B8E),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userData: widget.userData),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones Rápidas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DashboardWidgets.buildQuickActionButton(
              'Registrar Acción',
              Icons.edit_note,
              const Color(0xFF4A9B8E),
              onTap: () => _showActionDialog(),
            ),
            DashboardWidgets.buildQuickActionButton(
              'Ver Sensores',
              Icons.sensors,
              Colors.blue,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.black,
                  builder: (context) => SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Series de Sensores (últimas 24h, por hora)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          ..._sensorSeries.entries
                            .where((entry) => entry.value.isNotEmpty)
                            .map((entry) {
                              final parametro = entry.key;
                              final series = entry.value;
                              Color color;
                              switch (parametro) {
                                case 'temperatura':
                                  color = Colors.redAccent;
                                  break;
                                case 'humedad_aire':
                                  color = Colors.blueAccent;
                                  break;
                                case 'humedad_suelo':
                                  color = Colors.green;
                                  break;
                                default:
                                  color = Colors.grey;
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_getParametroLabel(parametro), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 180,
                                    child: SensorChartWidget(series: series, label: _getParametroLabel(parametro), color: color),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            DashboardWidgets.buildQuickActionButton(
              'Mi Perfil',
              Icons.person,
              Colors.orange,
              onTap: () => _navigateToProfile(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFloatingButtons() {
    return FloatingActionButton(
      heroTag: 'chat',
      onPressed: () {
        // Buscar el primer nodo activo
        Map<String, dynamic>? nodoPrincipal;
        if (_nodosSensores.isNotEmpty) {
          nodoPrincipal = _nodosSensores.firstWhere(
            (n) => n['activo'] == true,
            orElse: () => _nodosSensores[0],
          );
        }
        final userDataWithDashboard = Map<String, dynamic>.from(widget.userData);
        userDataWithDashboard['nodo_data'] = nodoPrincipal;
        userDataWithDashboard['crop_data'] = nodoPrincipal != null ? nodoPrincipal['sensores'] : null;
        userDataWithDashboard['alerts'] = _alerts;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ChatBotScreen(userData: userDataWithDashboard),
        );
      },
      backgroundColor: const Color(0xFF4A9B8E),
      child: const Icon(Icons.chat, color: Colors.white),
    );
  }

  void _showCreateTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'riego';
    String selectedPriority = 'media';
    DateTime selectedDateTime = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF23272A),
          title: const Row(
            children: [
              Icon(Icons.add_task, color: Color(0xFF4A9B8E)),
              SizedBox(width: 8),
              Text(
                'Crear Nueva Tarea',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF23272A),
                    labelText: 'Título de la tarea',
                    labelStyle: const TextStyle(color: Color(0xFF4A9B8E)),
                    hintText: 'Ej: Riego de parcela A',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4A9B8E)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4A9B8E)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF4A9B8E)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Descripción
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF23272A),
                    labelText: 'Descripción (opcional)',
                    labelStyle: const TextStyle(color: Color(0xFF4A9B8E)),
                    hintText: 'Describe los detalles de la tarea...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4A9B8E)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4A9B8E)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF4A9B8E)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Tipo de tarea
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: const Color(0xFF23272A),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF23272A),
                    labelText: 'Tipo de tarea',
                    labelStyle: const TextStyle(color: Color(0xFF4A9B8E)),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4A9B8E)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4A9B8E)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF4A9B8E)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'riego',
                      child: Row(
                        children: [
                          Icon(Icons.water_drop, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text('Riego'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'fertilizacion',
                      child: Row(
                        children: [
                          Icon(Icons.eco, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('Fertilización'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'poda',
                      child: Row(
                        children: [
                          Icon(Icons.content_cut, color: Colors.brown, size: 20),
                          SizedBox(width: 8),
                          Text('Poda'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'cosecha',
                      child: Row(
                        children: [
                          Icon(Icons.agriculture, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text('Cosecha'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'control_plagas',
                      child: Row(
                        children: [
                          Icon(Icons.bug_report, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Control de Plagas'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'analisis_suelo',
                      child: Row(
                        children: [
                          Icon(Icons.science, color: Colors.purple, size: 20),
                          SizedBox(width: 8),
                          Text('Análisis de Suelo'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Prioridad
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  dropdownColor: const Color(0xFF23272A),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFF23272A),
                    labelText: 'Prioridad',
                    labelStyle: const TextStyle(color: Color(0xFF4A9B8E)),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4A9B8E)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4A9B8E)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF4A9B8E)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'alta',
                      child: Row(
                        children: [
                          Icon(Icons.priority_high, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Alta'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'media',
                      child: Row(
                        children: [
                          Icon(Icons.remove, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text('Media'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'baja',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('Baja'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedPriority = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Fecha
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF4A9B8E),
                              onPrimary: Colors.white,
                              surface: Color(0xFF2A2A2A),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      setDialogState(() {
                        selectedDateTime = pickedDate;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fecha: ${DateFormat('dd/MM/yyyy').format(selectedDateTime)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Icon(Icons.calendar_today, color: Color(0xFF4A9B8E)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Hora
                InkWell(
                  onTap: () async {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF4A9B8E),
                              onPrimary: Colors.white,
                              surface: Color(0xFF2A2A2A),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedTime != null) {
                      setDialogState(() {
                        selectedTime = pickedTime;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hora: ${selectedTime.format(context)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Icon(Icons.access_time, color: Color(0xFF4A9B8E)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingresa un título para la tarea'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Aquí se enviaría la tarea al backend
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Tarea "${titleController.text}" creada exitosamente'),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF4A9B8E),
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'Ver',
                      textColor: Colors.white,
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 4; // Ir a calendario
                        });
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A9B8E),
              ),
              child: const Text('Crear Tarea'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4A9B8E),
        unselectedItemColor: Colors.grey[500],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.landscape),
            label: 'Parcelas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alertas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}