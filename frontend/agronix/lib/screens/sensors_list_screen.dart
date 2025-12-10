import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:agronix/widgets/sensor_chart_widget.dart';
import 'package:agronix/config/api_config.dart';

class SensorsListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> nodos;
  const SensorsListScreen({Key? key, required this.nodos}) : super(key: key);

  @override
  State<SensorsListScreen> createState() => _SensorsListScreenState();
}

class _SensorsListScreenState extends State<SensorsListScreen> {
  Map<String, List<Map<String, dynamic>>> _seriesPorSensor = {};

  @override
  void initState() {
    super.initState();
    _cargarSeriesPorSensor();
  }

  Future<void> _cargarSeriesPorSensor() async {
    // Obtener parcelaId del primer nodo (asumiendo todos son de la misma parcela)
    final parcelaId = widget.nodos.isNotEmpty ? widget.nodos[0]['parcela_id'] ?? 1 : 1;
    final userToken = ''; // Si tienes el token pásalo aquí
    final sensores = <String>{};
    for (final nodo in widget.nodos) {
      final sensoresNodo = nodo['sensores'] as Map<String, dynamic>? ?? {};
      sensores.addAll(sensoresNodo.keys);
    }
    Map<String, List<Map<String, dynamic>>> series = {};
    for (final sensor in sensores) {
      final url = '${ApiConfig.baseUrl}api/brain/series/?parcela=$parcelaId&parametro=$sensor&period=hour&interval=1';
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            // 'Authorization': 'Token $userToken', // Descomenta si usas token
          },
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic> && data.containsKey('points')) {
            series[sensor] = List<Map<String, dynamic>>.from(data['points']);
          } else if (data is List) {
            series[sensor] = List<Map<String, dynamic>>.from(data);
          } else {
            series[sensor] = [];
          }
        }
      } catch (e) {
        debugPrint('Error al obtener serie de $sensor: $e');
      }
    }
    setState(() {
      _seriesPorSensor = series;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensores por Nodo'),
        backgroundColor: const Color(0xFF4A9B8E),
      ),
      backgroundColor: const Color(0xFF1A1A1A),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.nodos.length,
        itemBuilder: (context, index) {
          final nodo = widget.nodos[index];
          final sensores = nodo['sensores'] as Map<String, dynamic>? ?? {};
          return Card(
            color: const Color(0xFF23272A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.only(bottom: 18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        nodo['activo'] == true ? Icons.sensors : Icons.sensors_off,
                        color: nodo['activo'] == true ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          nodo['nombre'] ?? 'Nodo',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: nodo['activo'] == true ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          nodo['activo'] == true ? 'Activo' : 'Inactivo',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sensores (${sensores.length}):',
                    style: const TextStyle(color: Color(0xFF4A9B8E), fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  if (sensores.isEmpty)
                    const Text('No hay sensores en este nodo.', style: TextStyle(color: Colors.grey)),
                  ...['temperatura', 'humedad_aire', 'humedad_suelo'].where((sensorKey) {
                    final series = _seriesPorSensor[sensorKey];
                    return series != null && series.isNotEmpty;
                  }).map((sensorKey) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4A9B8E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Text(
                            sensorKey == 'temperatura' ? 'Temperatura' : sensorKey == 'humedad_aire' ? 'Humedad Aire' : sensorKey == 'humedad_suelo' ? 'Humedad Suelo' : sensorKey,
                            style: const TextStyle(color: Color(0xFF4A9B8E), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            sensores[sensorKey]?.toString() ?? '--',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 0, top: 8, bottom: 8),
                        child: SizedBox(
                          height: 180,
                          child: SensorChartWidget(
                            series: _seriesPorSensor[sensorKey] ?? [],
                            label: sensorKey == 'temperatura' ? 'Temperatura' : sensorKey == 'humedad_aire' ? 'Humedad Aire' : sensorKey == 'humedad_suelo' ? 'Humedad Suelo' : sensorKey,
                            color: sensorKey == 'temperatura' ? Colors.redAccent : sensorKey == 'humedad_aire' ? Colors.blueAccent : sensorKey == 'humedad_suelo' ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
