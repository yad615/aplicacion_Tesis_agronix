import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agronix/config/api_config.dart';

// Asegúrate de que este import apunte a tu modelo real
import 'package:agronix/models/calendar_event.dart';

class CalendarScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CalendarScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // --- CONFIGURACIÓN ---
  final String baseUrl = ApiConfig.baseUrl;

  // --- VARIABLES DE ESTADO ---
  List<Map<String, dynamic>> _parcelas = [];
  int? _selectedParcelaId;

  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();
  List<CalendarEvent> events = [];
  bool _isLoading = false;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    _loadParcelas();
  }

  // --- 1. CARGA DE DATOS (PARCELAS) ---
  Future<void> _loadParcelas() async {
    final String? userToken = widget.userData['token'] as String?;
    if (userToken == null) return;
    try {
      final url = '$baseUrl/parcelas/';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token $userToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> results = decoded is Map && decoded.containsKey('results')
            ? decoded['results']
            : (decoded is List ? decoded : []);

        setState(() {
          _parcelas = List<Map<String, dynamic>>.from(results);
          if (_parcelas.isNotEmpty && _selectedParcelaId == null) {
            _selectedParcelaId = _parcelas.first['id'];
          }
        });

        if (_selectedParcelaId != null) {
          _loadEvents();
        }
      }
    } catch (e) {
      debugPrint('Error cargando parcelas: $e');
    }
  }

  // --- 2. OBTENER TAREAS (GET) ---
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      final String? userToken = widget.userData['token'] as String?;
      final parcelaId = _selectedParcelaId ?? widget.userData['parcela_id'];

      if (userToken == null) {
        setState(() => _isLoading = false);
        return;
      }

      String url = '$baseUrl/tareas/';
      if (parcelaId != null) {
        url += '?parcela=$parcelaId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token $userToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> tasksData = decoded is Map && decoded.containsKey('results')
            ? decoded['results']
            : [];

        setState(() {
          events = tasksData.map((taskJson) {
            // Asegúrate de que tu modelo CalendarEvent tenga soporte para 'origen' si quieres usarlo
            // Si no lo tiene, modifica CalendarEvent.fromJson para incluirlo o usa un campo map extra
            return CalendarEvent.fromJson(taskJson);
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading events: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 3. CREAR TAREA MANUAL (POST) ---
  Future<void> _createManualTask({
    required int? parcelaId,
    required String tipo,
    required String descripcion,
    required DateTime fecha,
    required String prioridad,
  }) async {
    final String? userToken = widget.userData['token'] as String?;

    if (userToken == null || parcelaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Falta información.'), backgroundColor: Colors.red),
      );
      return;
    }

    final url = '$baseUrl/tareas/';
    final body = json.encode({
      "parcela_id": parcelaId,
      "tipo": tipo.toLowerCase(),
      "descripcion": descripcion,
      "fecha_programada": DateFormat('yyyy-MM-dd').format(fecha),
      "prioridad": prioridad.toLowerCase(),
      "origen": "manual"
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token $userToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tarea creada correctamente.'), backgroundColor: Colors.green),
        );
        _loadEvents();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- HELPERS (Movidos al nivel correcto de la clase) ---

  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('es_ES', null);
      setState(() => _localeInitialized = true);
    } catch (e) {
      setState(() => _localeInitialized = true);
    }
  }

  String _getPriorityText(Priority priority) {
    if (priority == Priority.high) return 'Alta';
    if (priority == Priority.medium) return 'Media';
    if (priority == Priority.low) return 'Baja';
    return '';
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.irrigation: return Icons.water_drop;
      case EventType.fertilization: return Icons.eco;
      case EventType.pestControl: return Icons.bug_report;
      case EventType.harvest: return Icons.agriculture;
      case EventType.soilAnalysis: return Icons.science;
      case EventType.pruning: return Icons.content_cut;
      default: return Icons.event;
    }
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.irrigation: return Colors.blue;
      case EventType.fertilization: return Colors.green;
      case EventType.pestControl: return Colors.red;
      case EventType.harvest: return Colors.orange;
      case EventType.soilAnalysis: return Colors.purple;
      case EventType.pruning: return Colors.brown;
      default: return Colors.grey;
    }
  }

  Color _getPriorityColor(Priority priority) {
    if (priority == Priority.high) return Colors.red;
    if (priority == Priority.medium) return Colors.orange;
    if (priority == Priority.low) return Colors.green;
    return Colors.grey;
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _getMonthTitle(DateTime date) {
    if (_localeInitialized) {
      String text = DateFormat('MMMM yyyy', 'es_ES').format(date);
      return "${text[0].toUpperCase()}${text.substring(1)}";
    }
    return DateFormat('MMMM yyyy').format(date);
  }

  int _firstDayOffset(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    if (firstDay.weekday == 7) return 0; // Domingo = 0
    return firstDay.weekday;
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF23272A),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF4A9B8E), width: 2),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    );
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildMonthNavigator(),
              const SizedBox(height: 10),
              _buildWeekDaysHeader(),
              const SizedBox(height: 10),
              _buildCalendarGrid(),
              const SizedBox(height: 20),
              _buildEventsList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTaskDialog(selectedDate),
        backgroundColor: const Color(0xFF4A9B8E),
        child: const Icon(Icons.add_task, color: Colors.white, size: 32),
        tooltip: 'Crear tarea',
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(color: const Color(0xFF4A9B8E), borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.calendar_month, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Calendario', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF4A9B8E)),
              tooltip: 'Crear tarea manual',
              onPressed: () => _showCreateTaskDialog(selectedDate),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF4A9B8E)),
              tooltip: 'Actualizar',
              onPressed: _loadEvents,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthNavigator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: () => setState(() => focusedDate = DateTime(focusedDate.year, focusedDate.month - 1)),
        ),
        Text(
          _getMonthTitle(focusedDate),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white),
          onPressed: () => setState(() => focusedDate = DateTime(focusedDate.year, focusedDate.month + 1)),
        ),
      ],
    );
  }

  Widget _buildWeekDaysHeader() {
    const weekDays = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.map((day) => SizedBox(
        width: 40,
        child: Center(child: Text(day, style: TextStyle(color: Colors.grey[400], fontSize: 12))),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(focusedDate.year, focusedDate.month + 1, 0).day;
    final firstDayOfWeek = _firstDayOffset(focusedDate);
    final totalCells = 42;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7, childAspectRatio: 1, crossAxisSpacing: 4, mainAxisSpacing: 4
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNumber = index - firstDayOfWeek + 1;
        if (index < firstDayOfWeek || dayNumber > daysInMonth) return Container();

        final cellDate = DateTime(focusedDate.year, focusedDate.month, dayNumber);
        final isToday = _isSameDay(cellDate, DateTime.now());
        final isSelected = _isSameDay(cellDate, selectedDate);
        final dayEvents = events.where((e) => _isSameDay(e.dateTime, cellDate)).toList();

        return GestureDetector(
          onTap: () => setState(() => selectedDate = cellDate),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4A9B8E) : (isToday ? const Color(0xFF4A9B8E).withOpacity(0.3) : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: dayEvents.isNotEmpty && !isSelected ? Border.all(color: const Color(0xFF4A9B8E)) : null,
            ),
            child: Stack(
              children: [
                Center(child: Text('$dayNumber', style: TextStyle(
                  color: isSelected || isToday ? Colors.white : Colors.grey[400],
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal
                ))),
                if (dayEvents.isNotEmpty)
                  Positioned(
                    bottom: 6, left: 0, right: 0,
                    child: Center(child: Container(width: 6, height: 6, decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.orange, shape: BoxShape.circle))),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventsList() {
    final selectedEvents = events.where((e) => _isSameDay(e.dateTime, selectedDate)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eventos del ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (_isLoading)
          const Padding(padding: EdgeInsets.only(top: 10), child: Center(child: CircularProgressIndicator(color: Color(0xFF4A9B8E)))),
        const SizedBox(height: 12),
        if (selectedEvents.isEmpty && !_isLoading)
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Icon(Icons.event_busy, color: Colors.grey[400], size: 40),
              const SizedBox(height: 8),
              Text('No hay eventos', style: TextStyle(color: Colors.grey[400])),
            ]),
          )
        else
          ...selectedEvents.map((event) => _buildEventItem(event)),
      ],
    );
  }

  Widget _buildEventItem(CalendarEvent event) {
    // Nota: Para que event.origen funcione, debe estar definido en tu modelo CalendarEvent.
    // Si no está en el modelo, puedes comentar la parte de los "chips" (etiquetas) o agregar el campo al modelo.
    // Aquí asumimos que lo tienes o que usas una extensión. Si da error, comenta las líneas de "origen".
    
    // Intenta acceder al origen de forma dinámica si el modelo no es estricto, o asume que existe.
    final String? origen = (event as dynamic).toJson()['origen']; // Hack si el campo no es público, mejor agrégalo al modelo.

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF23272A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: InkWell(
        onTap: () => _showTaskDetailsDialog(event),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(_getEventTypeIcon(event.type), color: _getEventTypeColor(event.type)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        // --- CHIPS DE ORIGEN (IA / MANUAL) ---
                        // Asegúrate de que tu CalendarEvent tenga el campo 'origen' o usa este bloque condicional seguro
                        if (origen == 'automatico' || origen == 'ia')
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('IA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                    const SizedBox(height: 4),
                    Text(DateFormat('HH:mm').format(event.dateTime), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(event.priority),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getPriorityText(event.priority),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF4A9B8E), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ]),
        ),
      ],
    );
  }

  // --- DIÁLOGOS ---

  void _showCreateTaskDialog(DateTime date) {
    final formKey = GlobalKey<FormState>();
    final tipoController = TextEditingController();
    final descripcionController = TextEditingController();
    String prioridad = 'media';
    int? dialogSelectedParcelaId = _selectedParcelaId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF23272A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Crear Tarea Manual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_parcelas.isNotEmpty) ...[
                        DropdownButtonFormField<int>(
                          value: dialogSelectedParcelaId,
                          dropdownColor: const Color(0xFF2A2A2A),
                          decoration: _inputDecoration('Parcela'),
                          items: _parcelas.map((p) => DropdownMenuItem<int>(
                            value: p['id'],
                            child: Text(p['nombre'] ?? 'Parcela ${p['id']}', style: const TextStyle(color: Colors.white)),
                          )).toList(),
                          onChanged: (value) => setStateDialog(() => dialogSelectedParcelaId = value),
                          validator: (value) => value == null ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: tipoController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Tipo (ej. riego, poda)'),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descripcionController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Descripción'),
                        validator: (v) => v!.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: prioridad,
                        dropdownColor: const Color(0xFF2A2A2A),
                        decoration: _inputDecoration('Prioridad'),
                        items: const [
                          DropdownMenuItem(value: 'baja', child: Text('Baja', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'media', child: Text('Media', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'alta', child: Text('Alta', style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (val) => prioridad = val!,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar', style: TextStyle(color: Colors.grey[400])),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      _createManualTask(
                        parcelaId: dialogSelectedParcelaId,
                        tipo: tipoController.text,
                        descripcion: descripcionController.text,
                        fecha: date,
                        prioridad: prioridad,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A9B8E),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTaskDetailsDialog(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF23272A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(event.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(Icons.description, 'Descripción', event.description),
              const SizedBox(height: 12),
              _detailRow(Icons.calendar_today, 'Fecha', DateFormat('dd/MM/yyyy').format(event.dateTime)),
              const SizedBox(height: 12),
              _detailRow(Icons.flag, 'Prioridad', _getPriorityText(event.priority)),
              const SizedBox(height: 12),
              _detailRow(Icons.category, 'Tipo', event.type.toString().split('.').last.toUpperCase()),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar', style: TextStyle(color: Color(0xFF4A9B8E))),
            ),
          ],
        );
      },
    );
  }
}