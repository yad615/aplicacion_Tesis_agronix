import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class WeeklyProgress {
  final String day;
  final double value;
  WeeklyProgress({required this.day, required this.value});
}

// ...existing code...

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
    // Ejemplo de datos semanales
    final data = [
      WeeklyProgress(day: 'Lun', value: 20),
      WeeklyProgress(day: 'Mar', value: 35),
      WeeklyProgress(day: 'Mié', value: 40),
      WeeklyProgress(day: 'Jue', value: 30),
      WeeklyProgress(day: 'Vie', value: 50),
      WeeklyProgress(day: 'Sáb', value: 45),
      WeeklyProgress(day: 'Dom', value: 38),
    ];

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
          SizedBox(
            height: 200,
            child: SfCartesianChart(
              backgroundColor: const Color(0xFF2A2A2A),
              primaryXAxis: CategoryAxis(
                labelStyle: const TextStyle(color: Colors.white),
                axisLine: const AxisLine(color: Colors.white),
                majorTickLines: const MajorTickLines(size: 0),
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: const TextStyle(color: Colors.white),
                axisLine: const AxisLine(color: Colors.white),
                majorTickLines: const MajorTickLines(size: 0),
                majorGridLines: const MajorGridLines(width: 0),
              ),
              series: <BarSeries<WeeklyProgress, String>>[
                BarSeries<WeeklyProgress, String>(
                  dataSource: data,
                  xValueMapper: (WeeklyProgress progress, _) => progress.day,
                  yValueMapper: (WeeklyProgress progress, _) => progress.value,
                  color: const Color(0xFF4A9B8E),
                  borderRadius: BorderRadius.circular(6),
                  width: 0.6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}