import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  int _selectedIndex = 0;
  bool _showChatBot = false;

  // Lista de widgets para cada pantalla
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _initializeScreens();
  }

  void _initializeScreens() {
    _screens = [
      _buildDashboardContent(),
      StatisticsScreen(userData: widget.userData),
      AlertsScreen(userData: widget.userData),
      CalendarScreen(userData: widget.userData),
      SettingsScreen(userData: widget.userData),
    ];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      ),
      floatingActionButton: _buildChatButton(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B4D3E),
            const Color(0xFF2D5A4A),
            const Color(0xFF4A9B8E),
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
                  DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedIndex = 2; // Ir a alertas
              });
            },
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white),
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
                    child: const Text(
                      '3',
                      style: TextStyle(
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
                  _buildCropStatusCards(),
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
          const Icon(Icons.refresh, color: Colors.grey, size: 16),
          const SizedBox(width: 8),
          Text(
            'Última actualización: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropStatusCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCropStatusCard(
                '🌡️ Temperatura del Aire',
                '25°C',
                'Óptimo',
                const Color(0xFF4A9B8E),
                Icons.thermostat,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCropStatusCard(
                '💧 Humedad Relativa',
                '70%',
                'Alta',
                Colors.blue,
                Icons.water_drop,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCropStatusCard(
                '🌱 Humedad del Suelo',
                '40%',
                'Moderada',
                const Color(0xFF1B4D3E),
                Icons.grass,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCropStatusCard(
                '⚡ Conductividad',
                '0.8 mS/cm',
                'Estable',
                Colors.orange,
                Icons.bolt,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCropStatusCard(
      String title, String value, String status, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
                  _selectedIndex = 2;
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
        _buildAlertCard(
          '🔔 Riesgo de plaga detectado en Parcela A',
          Colors.red,
          Icons.warning,
        ),
        const SizedBox(height: 8),
        _buildAlertCard(
          '🧠 Aplicar riego en Parcela B esta tarde',
          const Color(0xFF4A9B8E),
          Icons.lightbulb_outline,
        ),
        const SizedBox(height: 8),
        _buildAlertCard(
          '📅 Cosecha programada mañana 8:00 a.m.',
          Colors.blue,
          Icons.calendar_today,
        ),
      ],
    );
  }

  Widget _buildAlertCard(String message, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
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
            _buildQuickActionButton(
              'Registrar Acción',
              Icons.edit_note,
              const Color(0xFF4A9B8E),
              onTap: () => _showActionDialog(),
            ),
            _buildQuickActionButton(
              'Calendario',
              Icons.calendar_today,
              Colors.blue,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
              },
            ),
            _buildQuickActionButton(
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
                hintText: 'Descripción de la acción',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
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

  Widget _buildQuickActionButton(String label, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatButton() {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          _showChatBot = !_showChatBot;
        });
        _showChatDialog();
      },
      backgroundColor: const Color(0xFF4A9B8E),
      child: const Icon(Icons.chat, color: Colors.white),
    );
  }

  void _showChatDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatBotScreen(userData: widget.userData),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.1)),
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

// Pantalla de Estadísticas
class StatisticsScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const StatisticsScreen({Key? key, required this.userData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estadísticas de Cultivos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildStatCard('Producción Total', '2,450 kg', Icons.agriculture, Colors.green),
          const SizedBox(height: 12),
          _buildStatCard('Eficiencia de Riego', '87%', Icons.water_drop, Colors.blue),
          const SizedBox(height: 12),
          _buildStatCard('Tiempo de Crecimiento', '45 días', Icons.schedule, Colors.orange),
          const SizedBox(height: 12),
          _buildStatCard('Calidad del Producto', '9.2/10', Icons.star, Colors.yellow),
          const SizedBox(height: 20),
          _buildChart(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progreso Semanal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 200,
            child: const Center(
              child: Text(
                'Gráfico de Progreso\n(Integración con charts_flutter)',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Pantalla de Alertas
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

// Pantalla de Calendario
class CalendarScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CalendarScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calendario Agrícola',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildCalendarHeader(),
          const SizedBox(height: 20),
          _buildEventsList(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedDate = DateTime(selectedDate.year, selectedDate.month - 1);
                  });
                },
                icon: const Icon(Icons.chevron_left, color: Colors.white),
              ),
              Text(
                DateFormat('MMMM yyyy').format(selectedDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedDate = DateTime(selectedDate.year, selectedDate.month + 1);
                  });
                },
                icon: const Icon(Icons.chevron_right, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: 35,
            itemBuilder: (context, index) {
              final day = index + 1;
              final isToday = day == DateTime.now().day &&
                  selectedDate.month == DateTime.now().month &&
                  selectedDate.year == DateTime.now().year;
              
              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFF4A9B8E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      color: isToday ? Colors.white : Colors.grey[400],
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Eventos de Hoy',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildEventItem(
          'Riego Parcela A',
          '08:00 AM',
          Icons.water_drop,
          Colors.blue,
        ),
        _buildEventItem(
          'Fertilización Parcela B',
          '10:30 AM',
          Icons.eco,
          Colors.green,
        ),
        _buildEventItem(
          'Revisión de Plagas',
          '02:00 PM',
          Icons.bug_report,
          Colors.red,
        ),
        _buildEventItem(
          'Cosecha Parcela C',
          '06:00 PM',
          Icons.agriculture,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildEventItem(String title, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
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
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Pantalla de Configuración
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
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nueva contraseña',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Confirmar nueva contraseña',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(),
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
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
              'Email: soporte@agronexus.com',
              style: TextStyle(color: Colors.grey),
            ),
            const Text(
              'Teléfono: +1 234 567 890',
              style: TextStyle(color: Colors.grey),
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

// Pantalla de Chat Bot
class ChatBotScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ChatBotScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _addBotMessage('¡Hola! Soy tu asistente IA. Pregúntame sobre tus cultivos, el clima o necesitas consejos para optimizar tu producción.');
  }

  void _addBotMessage(String message) {
    setState(() {
      _messages.add(ChatMessage(
        message: message,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _addUserMessage(String message) {
    setState(() {
      _messages.add(ChatMessage(
        message: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });
    _messageController.clear();
    
    // Simular respuesta del bot
    Future.delayed(const Duration(seconds: 1), () {
      _addBotMessage(_getBotResponse(message));
    });
  }

  String _getBotResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    if (message.contains('riego') || message.contains('agua')) {
      return 'Según los datos de tus sensores, recomiendo regar la Parcela B esta tarde. La humedad del suelo está al 40%.';
    } else if (message.contains('plaga') || message.contains('insecto')) {
      return 'He detectado actividad de plagas en la Parcela A. Te sugiero aplicar tratamiento orgánico inmediatamente.';
    } else if (message.contains('clima') || message.contains('tiempo')) {
      return 'El clima actual es favorable: 25°C con 70% de humedad. Ideal para el crecimiento de tus cultivos.';
    } else if (message.contains('cosecha')) {
      return 'Basándome en el ciclo de crecimiento, la Parcela C estará lista para cosecha en 3 días.';
    } else if (message.contains('fertilizante') || message.contains('nutrientes')) {
      return 'Los niveles de nutrientes están estables. Recomiendo fertilización orgánica la próxima semana.';
    } else {
      return 'Entiendo tu consulta. ¿Podrías ser más específico sobre qué aspecto de tu cultivo te interesa? Puedo ayudarte con riego, plagas, clima, cosecha o fertilización.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4A9B8E),
                  const Color(0xFF1B4D3E),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.white),
                const SizedBox(width: 12),
                const Text(
                  'Asistente IA AgroNexus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Escribe tu pregunta...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _addUserMessage(value.trim());
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_messageController.text.trim().isNotEmpty) {
                      _addUserMessage(_messageController.text.trim());
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A9B8E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
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

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: message.isUser 
              ? const Color(0xFF4A9B8E) 
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modelo para mensajes de chat
class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.message,
    required this.isUser,
    required this.timestamp,
  });
}

// Pantalla de Perfil Mejorada
class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController fullNameController;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController(text: widget.userData['username'] ?? '');
    emailController = TextEditingController(text: widget.userData['email'] ?? '');
    fullNameController = TextEditingController(
      text: widget.userData['full_name'] ?? 
            '${widget.userData['first_name'] ?? ''} ${widget.userData['last_name'] ?? ''}'.trim()
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    fullNameController.dispose();
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
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
              });
              if (!isEditing) {
                _saveProfile();
              }
            },
            child: Text(
              isEditing ? 'Guardar' : 'Editar',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                widget.userData['username']?.substring(0, 1).toUpperCase() ?? 'U',
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
          widget.userData['username'] ?? 'Usuario',
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
            enabled: isEditing,
          ),
          _buildDivider(),
          _buildProfileField(
            'Correo Electrónico',
            emailController,
            Icons.email,
            enabled: isEditing,
          ),
          _buildDivider(),
          _buildProfileField(
            'Nombre Completo',
            fullNameController,
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

  void _saveProfile() {
    // Aquí implementarías la lógica para guardar los cambios
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perfil actualizado exitosamente'),
        backgroundColor: Color(0xFF4A9B8E),
      ),
    );
  }
}