import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class WeeklyProgress {
  final String day;
  final double value;
  WeeklyProgress({required this.day, required this.value});
}

class ChartPoint {
  final String date;
  final double? value;
  ChartPoint(this.date, this.value);
}

class StatisticsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const StatisticsScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Map<String, dynamic>> _parcelas = [];
  bool _isLoadingParcelas = true;
  List<Map<String, dynamic>> _latestNodes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadParcelasIfNeeded().then((_) => _loadLatestNodesData());
  }

  Future<void> _loadLocalOrRemoteSeries() async {
    await _loadLatestNodesData();
  }

  Future<void> _loadParcelasIfNeeded() async {
    final userToken = widget.userData['token'];
    if (ApiConfig.baseUrl.isEmpty || userToken == null) {
      setState(() {
        _isLoadingParcelas = false;
        _errorMessage = 'Falta configuración de usuario.';
      });
      return;
    }

    setState(() => _isLoadingParcelas = true);

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
          _isLoadingParcelas = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoadingParcelas = false;
          _errorMessage = 'Error al cargar parcelas (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingParcelas = false;
        _errorMessage = 'No se pudo cargar las parcelas.';
      });
    }
  }

  Future<void> _loadLatestNodesData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final parcelaId = widget.userData['parcela_id'];
    final userToken = widget.userData['token'];

    if (parcelaId == null || userToken == null || ApiConfig.baseUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Datos insuficientes.';
      });
      return;
    }

    final url =
        '${ApiConfig.baseUrl}/api/brain/nodes/latest/?parcela=$parcelaId';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $userToken',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final nodos = data['nodos'] as List? ?? [];

        setState(() {
          _latestNodes =
              nodos.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Error al cargar datos (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'No se pudo cargar los datos de sensores.';
      });
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _normalizeDateString(dynamic dateField) {
    if (dateField == null) return '';
    if (dateField is String) {
      try {
        final dt = DateTime.parse(dateField);
        return dt.toIso8601String().substring(0, 10);
      } catch (_) {
        return dateField.length >= 10 ? dateField.substring(0, 10) : dateField;
      }
    }
    if (dateField is int) {
      final dt =
          DateTime.fromMillisecondsSinceEpoch(dateField * 1000);
      return dt.toIso8601String().substring(0, 10);
    }
    return dateField.toString();
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

  // ============================================================
  // MÉTRICAS (CORREGIDO)
  // ============================================================

  Widget _buildMetricsSummary() {
    int totalDias = 0;
    int diasSinDatos = 0;

    int totalAlertas = widget.userData['alertas'] is List
        ? (widget.userData['alertas'] as List).length
        : 0;

    Map<String, double> promedios = {};

    if (_latestNodes.isNotEmpty) {
      final fechas = _latestNodes
          .map((e) => _normalizeDateString(e['timestamp']))
          .toSet();

      totalDias = fechas.length;

      for (final entry in _latestNodes) {
        final sensores = entry['sensores'] ?? {};
        final values = sensores.values
            .map((e) => (e as num?)?.toDouble() ?? 0.0)
            .toList();

        if (values.isNotEmpty) {
          promedios[entry['nodo']] =
              values.reduce((a, b) => a + b) / values.length;
        }
      }
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF23272A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de métricas',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricCard(
                    'Días con datos', totalDias.toString(),
                    Icons.calendar_today, Colors.blue),
                _buildMetricCard(
                    'Alertas', totalAlertas.toString(),
                    Icons.warning_amber_rounded, Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            if (promedios.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: promedios.entries
                    .map((e) => Text(
                          'Promedio nodo ${e.key}: ${e.value.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GRÁFICO PRINCIPAL
  // ============================================================

  Widget _buildCombinedChart() {
    final parametros = ['temperatura', 'humedad_aire', 'humedad_suelo'];

    final colors = {
      'temperatura': Colors.orange,
      'humedad_aire': Colors.blue,
      'humedad_suelo': Colors.green,
    };

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            const Text(
              'Sensores actuales por nodo',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: SfCartesianChart(
                legend: Legend(
                    isVisible: true,
                    textStyle: const TextStyle(color: Colors.white)),
                primaryXAxis: CategoryAxis(
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                primaryYAxis: NumericAxis(
                  labelStyle: const TextStyle(color: Colors.white),
                ),
                series: parametros.map((parametro) {
                  return ColumnSeries<Map<String, dynamic>, String>(
                    name: _getParametroLabel(parametro),
                    color: colors[parametro],
                    dataSource: _latestNodes,
                    xValueMapper: (node, _) => node['nodo'] ?? '',
                    yValueMapper: (node, _) {
                      final sensores = node['sensores'];
                      if (sensores == null ||
                          sensores[parametro] == null) return null;

                      final valor = sensores[parametro];
                      return valor is num ? valor.toDouble() : null;
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD COMPLETO (CORREGIDO)
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161616),
      appBar: AppBar(
        title: const Text('Estadísticas'),
        backgroundColor: const Color(0xFF1F1F1F),
        actions: [
          IconButton(
            onPressed: _isLoadingParcelas ? null : _loadParcelasIfNeeded,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: _isLoadingParcelas
          ? const Center(child: CircularProgressIndicator())
          : (_errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _parcelas.isEmpty
                  ? const Center(
                      child: Text(
                        "No hay parcelas registradas.",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          _buildMetricsSummary(),
                          _buildCombinedChart(),
                        ],
                      ),
                    )),
    );
  }
}
