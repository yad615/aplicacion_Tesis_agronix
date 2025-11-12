import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

import 'package:agronix/screens/statistics_screen.dart';
import 'package:agronix/screens/alerts_screen.dart';
import 'package:agronix/screens/calendar_screen.dart';
import 'package:agronix/screens/settings_screen.dart';
import 'package:agronix/screens/profile_screen.dart';
import 'package:agronix/screens/chatbot_screen.dart';
import 'package:agronix/screens/parcelas_screen.dart';
import 'package:agronix/widgets/dashboard_widgets.dart';
import 'package:agronix/services/endpoints/endpoints.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({super.key, required this.userData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  int _selectedIndex = 0;

  // Datos del cultivo que se cargarán del backend
  Map<String, dynamic>? _cropData;
  List<Map<String, dynamic>> _alerts = [];

  bool _isLoading = true;
  String _lastUpdateMessage = 'Cargando datos...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _loadInitialData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Método corregido para cargar datos
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _lastUpdateMessage = 'Cargando datos...';
    });

    final String? userToken = widget.userData['token'] as String?;
    if (userToken == null || userToken.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _lastUpdateMessage = 'Error: No autenticado.';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ChatbotEndpoints.cropData),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
      );
      
      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData.containsKey('crop_data')) {
          setState(() {
            _cropData = responseData['crop_data'];
            
            if (_cropData!['last_updated'] is String) {
              _cropData!['last_updated'] = DateTime.parse(_cropData!['last_updated']);
            }
            
            _lastUpdateMessage = 'Última actualización: ${DateFormat('dd/MM/yyyy HH:mm').format(_cropData!['last_updated'])}';
            _updateAlertsBasedOnData();
          });
        } else {
          debugPrint("Backend no devolvió datos válidos: $responseData");
          await _generateFreshSimulatedData();
        }
      } else {
        debugPrint('Error HTTP: ${response.statusCode} - ${response.body}');
        await _generateFreshSimulatedData();
      }
    } catch (e) {
      debugPrint('Excepción: $e');
      if (mounted) {
        await _generateFreshSimulatedData();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateFreshSimulatedData() async {
    setState(() {
      _cropData = {
        'temperature_air': double.parse((18.0 + Random().nextDouble() * 10.0).toStringAsFixed(1)),
        'humidity_air': double.parse((55.0 + Random().nextDouble() * 30.0).toStringAsFixed(1)),
        'humidity_soil': double.parse((30.0 + Random().nextDouble() * 40.0).toStringAsFixed(1)),
        'conductivity_ec': double.parse((0.5 + Random().nextDouble() * 1.0).toStringAsFixed(2)),
        'temperature_soil': double.parse((12.0 + Random().nextDouble() * 16.0).toStringAsFixed(1)),
        'solar_radiation': double.parse((250.0 + Random().nextDouble() * 600.0).toStringAsFixed(1)),
        'pest_risk': ['Bajo', 'Moderado', 'Alto'][Random().nextInt(3)],
        'last_updated': DateTime.now(),
      };
      _lastUpdateMessage = 'Última actualización: ${DateFormat('dd/MM/yyyy HH:mm').format(_cropData!['last_updated'])}';
      _updateAlertsBasedOnData();
    });
  }

  Future<void> _refreshData() async {
    await _loadInitialData();
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
      case 'temperature_soil':
        if (value < 15.0) return 'Bajo';
        if (value > 25.0) return 'Alto';
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
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
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : _refreshData,
            icon: _isLoading 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedIndex = 3; 
              });
            },
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white),
                if (_alerts.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${_alerts.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
                  _buildLastUpdate(),
                  const SizedBox(height: 20),
                  _isLoading ? _buildLoadingCards() : _buildCropStatusCards(),
                  const SizedBox(height: 20),
                  _buildAlertsSection(),
                  const SizedBox(height: 20),
                  _buildQuickActions(),
                  const SizedBox(height: 80),
                ],
              ),
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
    if (_cropData == null) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DashboardWidgets.buildCropStatusCard(
                '🌡️ Temperatura del Aire',
                '${_cropData!['temperature_air']}°C',
                _getParameterStatus('temperature_air', _cropData!['temperature_air'] as double),
                _getStatusColor(_getParameterStatus('temperature_air', _cropData!['temperature_air'] as double)),
                Icons.thermostat,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardWidgets.buildCropStatusCard(
                '💧 Humedad Relativa',
                '${_cropData!['humidity_air']}%',
                _getParameterStatus('humidity_air', _cropData!['humidity_air'] as double),
                _getStatusColor(_getParameterStatus('humidity_air', _cropData!['humidity_air'] as double)),
                Icons.water_drop,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DashboardWidgets.buildCropStatusCard(
                '🌱 Humedad del Suelo',
                '${_cropData!['humidity_soil']}%',
                _getParameterStatus('humidity_soil', _cropData!['humidity_soil'] as double),
                _getStatusColor(_getParameterStatus('humidity_soil', _cropData!['humidity_soil'] as double)),
                Icons.grass,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DashboardWidgets.buildCropStatusCard(
                '⚡ Conductividad',
                '${_cropData!['conductivity_ec']} dS/m',
                _getParameterStatus('conductivity_ec', _cropData!['conductivity_ec'] as double),
                _getStatusColor(_getParameterStatus('conductivity_ec', _cropData!['conductivity_ec'] as double)),
                Icons.bolt,
              ),
            ),
          ],
        ),
      ],
    );
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
              'Parcelas',
              Icons.landscape,
              Colors.green,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón para crear tarea
        FloatingActionButton(
          heroTag: 'create_task',
          onPressed: () => _showCreateTaskDialog(),
          backgroundColor: Colors.orange,
          child: const Icon(Icons.add_task, color: Colors.white),
        ),
        const SizedBox(height: 12),
        // Botón del chatbot
        FloatingActionButton(
          heroTag: 'chat',
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => ChatBotScreen(userData: widget.userData),
            );
          },
          backgroundColor: const Color(0xFF4A9B8E),
          child: const Icon(Icons.chat, color: Colors.white),
        ),
      ],
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