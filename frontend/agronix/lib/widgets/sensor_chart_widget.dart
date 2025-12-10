import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SensorChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> series;
  final String label;
  final Color color;

  const SensorChartWidget({
    Key? key,
    required this.series,
    required this.label,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Text('Sin datos para graficar', style: TextStyle(color: Colors.grey)),
      );
    }
    final spots = series
        .where((item) => item['value'] != null)
        .map((item) => FlSpot(
              (series.indexOf(item)).toDouble(),
              (item['value'] as num).toDouble(),
            ))
        .toList();

    // Si solo hay un dato, dibuja una línea horizontal y un punto grande
    List<FlSpot> displaySpots = List.from(spots);
    bool singlePoint = spots.length == 1;
    if (singlePoint) {
      // Añade un segundo punto para que la línea se vea
      displaySpots.add(FlSpot(spots[0].x + 1, spots[0].y));
    }
    return Container(
      height: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF181C1F),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Promedio por periodo',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.18),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: (displaySpots.length / 4).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx < 0 || idx >= series.length) return const SizedBox.shrink();
                        final item = series[idx];
                        final date = item['date'] ?? item['timestamp'] ?? '';
                        String label = '';
                        if (date is String && date.isNotEmpty) {
                          label = date.length > 10 ? date.substring(0, 10) : date;
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withOpacity(0.18)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: displaySpots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.18), color.withOpacity(0.04)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: FlDotData(
                      show: singlePoint,
                      getDotPainter: (spot, percent, bar, index) {
                        if (singlePoint) {
                          return FlDotCirclePainter(
                            radius: 6,
                            color: color,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        }
                        return FlDotCirclePainter(
                          radius: 0,
                          color: Colors.transparent,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
