import 'package:flutter/material.dart';
import 'dart:math' as math;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _chartAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  int _selectedIndex = 0;
  bool _showChatBot = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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
    Future.delayed(const Duration(milliseconds: 500), () {
      _chartAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _chartAnimationController.dispose();
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
            Expanded(
              child: SingleChildScrollView(
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
                            _buildQuickStats(),
                            const SizedBox(height: 20),
                            _buildMonitoringCards(),
                            const SizedBox(height: 20),
                            _buildCharts(),
                            const SizedBox(height: 20),
                            _buildInsightsCard(),
                            const SizedBox(height: 80),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
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
        // 🔄 CAMBIO AQUÍ: Reemplazar el Container con ícono por el logo
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/images/logo.png', // 👈 TU LOGO AQUÍ
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              // Si tu logo no se ve bien con el fondo, puedes agregar un color de fondo:
              // color: Colors.white, // Descomenta si necesitas colorear el logo
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Agronix',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Cultivo de Fresas - San Andreas',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
        ),
      ],
    ),
  );
}

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Salud del Cultivo',
            '94%',
            '+2%',
            Icons.eco,
            Colors.green,
            '2% mejor que la semana pasada',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Estado del Riego',
            'Óptimo',
            'Estable',
            Icons.water_drop,
            const Color(0xFF4A9B8E),
            'Próximo riego en 3h 45m',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String change, IconData icon,
      Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Alertas de Seguridad',
            '2',
            '-75%',
            Icons.security,
            Colors.orange,
            '75% menos que el mes pasado',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Estado de Plagas',
            '1 activa',
            '+1',
            Icons.bug_report,
            Colors.red,
            '3 en monitoreo',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String change,
      IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
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
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts() {
    return Row(
      children: [
        Expanded(
          child: _buildChartCard(
            'Salud del Cultivo',
            'Tendencia semanal',
            _buildHealthChart(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildChartCard(
            'Consumo de Agua',
            'Litros por día',
            _buildWaterChart(),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(String title, String subtitle, Widget chart) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: chart),
        ],
      ),
    );
  }

  Widget _buildHealthChart() {
    return AnimatedBuilder(
      animation: _chartAnimationController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, double.infinity),
          painter: HealthChartPainter(_chartAnimationController.value),
        );
      },
    );
  }

  Widget _buildWaterChart() {
    return AnimatedBuilder(
      animation: _chartAnimationController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, double.infinity),
          painter: WaterChartPainter(_chartAnimationController.value),
        );
      },
    );
  }

  Widget _buildInsightsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4A9B8E).withOpacity(0.1),
            const Color(0xFF1B4D3E).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A9B8E).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A9B8E).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF4A9B8E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Insights de IA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Análisis y recomendaciones basadas en los datos actuales',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            'Salud del Cultivo',
            'Excelente Crecimiento',
            'Las condiciones actuales son óptimas para el desarrollo de las fresas.',
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'Riego',
            'Programación Eficiente',
            'El sistema de riego está optimizado para el clima actual.',
            const Color(0xFF4A9B8E),
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'Clima',
            'Condiciones Favorables',
            'Las próximas 48 horas presentan condiciones ideales.',
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String category, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[400],
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
      builder: (context) => Container(
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A9B8E).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                Icons.smart_toy,
                                size: 40,
                                color: Color(0xFF4A9B8E),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '¡Hola! Soy tu asistente IA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pregúntame sobre tus cultivos, el clima o necesitas consejos para optimizar tu producción.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Escribe tu pregunta...',
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco),
            label: 'Cultivos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop),
            label: 'Riego',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Seguridad',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendario',
          ),
        ],
      ),
    );
  }
}

class HealthChartPainter extends CustomPainter {
  final double animationValue;

  HealthChartPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.green.withOpacity(0.3),
          Colors.green.withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final points = [
      const Offset(0, 0.8),
      const Offset(0.2, 0.6),
      const Offset(0.4, 0.4),
      const Offset(0.6, 0.3),
      const Offset(0.8, 0.2),
      const Offset(1.0, 0.1),
    ];

    for (int i = 0; i < points.length; i++) {
      final x = points[i].dx * size.width;
      final y = points[i].dy * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final animatedIndex = (animationValue * points.length).floor();
        if (i <= animatedIndex) {
          path.lineTo(x, y);
          fillPath.lineTo(x, y);
        }
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WaterChartPainter extends CustomPainter {
  final double animationValue;

  WaterChartPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4A9B8E)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF4A9B8E).withOpacity(0.3),
          const Color(0xFF4A9B8E).withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final points = [
      const Offset(0, 0.3),
      const Offset(0.2, 0.2),
      const Offset(0.4, 0.4),
      const Offset(0.6, 0.1),
      const Offset(0.8, 0.3),
      const Offset(1.0, 0.5),
    ];

    for (int i = 0; i < points.length; i++) {
      final x = points[i].dx * size.width;
      final y = points[i].dy * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final animatedIndex = (animationValue * points.length).floor();
        if (i <= animatedIndex) {
          path.lineTo(x, y);
          fillPath.lineTo(x, y);
        }
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}