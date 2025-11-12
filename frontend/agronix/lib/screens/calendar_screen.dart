import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agronix/services/endpoints/endpoints.dart';
import 'package:agronix/models/calendar_event.dart';

class CalendarScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CalendarScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    CalendarEventBus().addListener(_onExternalEvent);
  }

  @override
  void dispose() {
    CalendarEventBus().removeListener(_onExternalEvent);
    super.dispose();
  }

  void _onExternalEvent(CalendarEvent event) {
    setState(() {
      events.add(event);
    });
  }
  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();
  List<CalendarEvent> events = [];
  bool _isLoading = false;
  bool _localeInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('es_ES', null);
      setState(() {
        _localeInitialized = true;
      });
      _loadEvents();
    } catch (e) {
      print('Error initializing locale: $e');
      setState(() {
        _localeInitialized = true;
      });
      _loadEvents();
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String? userToken = widget.userData['token'] as String?;
      if (userToken == null) {
        _loadMockEvents();
        return;
      }

      final response = await http.get(
        Uri.parse(TaskEndpoints.list),
        headers: {
          'Authorization': 'Bearer $userToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> tasksData = json.decode(response.body);
        setState(() {
          events = tasksData.map((task) => CalendarEvent.fromJson(task)).toList();
        });
      } else {
        _loadMockEvents();
      }
    } catch (e) {
      print('Error loading events: $e');
      _loadMockEvents();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadMockEvents() {
    final now = DateTime.now();
    setState(() {
      events = [
        CalendarEvent(
          id: '1',
          title: 'Riego Parcela A',
          description: 'Riego programado para la parcela A',
          dateTime: DateTime(now.year, now.month, now.day, 8, 0),
          type: EventType.irrigation,
          priority: Priority.high,
        ),
        CalendarEvent(
          id: '2',
          title: 'Fertilización Parcela B',
          description: 'Aplicación de fertilizante NPK',
          dateTime: DateTime(now.year, now.month, now.day, 10, 30),
          type: EventType.fertilization,
          priority: Priority.medium,
        ),
        CalendarEvent(
          id: '3',
          title: 'Revisión de Plagas',
          description: 'Inspección de plagas y enfermedades',
          dateTime: DateTime(now.year, now.month, now.day, 14, 0),
          type: EventType.pestControl,
          priority: Priority.high,
        ),
        CalendarEvent(
          id: '4',
          title: 'Cosecha Parcela C',
          description: 'Recolección de fresas maduras',
          dateTime: DateTime(now.year, now.month, now.day, 18, 0),
          type: EventType.harvest,
          priority: Priority.medium,
        ),
        CalendarEvent(
          id: '5',
          title: 'Análisis de Suelo',
          description: 'Toma de muestras para análisis',
          dateTime: DateTime(now.year, now.month, now.day + 1, 9, 0),
          type: EventType.soilAnalysis,
          priority: Priority.low,
        ),
        CalendarEvent(
          id: '6',
          title: 'Poda de Plantas',
          description: 'Poda de hojas y estolones',
          dateTime: DateTime(now.year, now.month, now.day + 2, 7, 30),
          type: EventType.pruning,
          priority: Priority.medium,
        ),
      ];
    });
  }

  List<CalendarEvent> _getEventsForDate(DateTime date) {
    return events.where((event) {
      return event.dateTime.year == date.year &&
          event.dateTime.month == date.month &&
          event.dateTime.day == date.day;
    }).toList();
  }

  List<CalendarEvent> _getEventsForSelectedDate() {
    return _getEventsForDate(selectedDate);
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _getFirstDayOfWeek(DateTime date) {
    return DateTime(date.year, date.month, 1).weekday % 7;
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9B8E)),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildCalendarHeader(),
          const SizedBox(height: 20),
          _buildEventsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Calendario Agrícola',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF4A9B8E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.agriculture, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                'Fresas',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
                    focusedDate = DateTime(focusedDate.year, focusedDate.month - 1);
                  });
                },
                icon: const Icon(Icons.chevron_left, color: Colors.white),
              ),
              Text(
                _formatMonthYear(focusedDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    focusedDate = DateTime(focusedDate.year, focusedDate.month + 1);
                  });
                },
                icon: const Icon(Icons.chevron_right, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildWeekDaysHeader(),
          const SizedBox(height: 8),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  String _formatMonthYear(DateTime date) {
    try {
      if (_localeInitialized) {
        return DateFormat('MMMM yyyy', 'es_ES').format(date);
      } else {
        return DateFormat('MMMM yyyy').format(date);
      }
    } catch (e) {
      const months = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];
      return '${months[date.month - 1]} ${date.year}';
    }
  }

  Widget _buildWeekDaysHeader() {
    const weekDays = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.map((day) => Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Text(
          day,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = _getDaysInMonth(focusedDate);
    final firstDayOfWeek = _getFirstDayOfWeek(focusedDate);
    final totalCells = 42;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNumber = index - firstDayOfWeek + 1;
        
        if (index < firstDayOfWeek || dayNumber > daysInMonth) {
          return Container();
        }

        final cellDate = DateTime(focusedDate.year, focusedDate.month, dayNumber);
        final isToday = _isSameDay(cellDate, DateTime.now());
        final isSelected = _isSameDay(cellDate, selectedDate);
        final dayEvents = _getEventsForDate(cellDate);
        final hasEvents = dayEvents.isNotEmpty;

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedDate = cellDate;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4A9B8E)
                  : isToday
                      ? const Color(0xFF4A9B8E).withOpacity(0.3)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: hasEvents
                  ? Border.all(color: const Color(0xFF4A9B8E), width: 1)
                  : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    dayNumber.toString(),
                    style: TextStyle(
                      color: isSelected || isToday ? Colors.white : Colors.grey[400],
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (hasEvents)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _getEventPriorityColor(dayEvents),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getEventPriorityColor(List<CalendarEvent> events) {
    if (events.any((e) => e.priority == Priority.high)) return Colors.red;
    if (events.any((e) => e.priority == Priority.medium)) return Colors.orange;
    return Colors.green;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildEventsList() {
    final selectedDateEvents = _getEventsForSelectedDate();
    final todayEvents = _getEventsForDate(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isSameDay(selectedDate, DateTime.now())
                  ? 'Eventos de Hoy'
                  : 'Eventos para ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9B8E)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (selectedDateEvents.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    color: Colors.grey[400],
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No hay eventos programados',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...selectedDateEvents.map((event) => _buildEventItem(event)),
        
        if (!_isSameDay(selectedDate, DateTime.now()) && todayEvents.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Eventos de Hoy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...todayEvents.map((event) => _buildEventItem(event)),
        ],
      ],
    );
  }

  Widget _buildEventItem(CalendarEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getEventTypeColor(event.type).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getEventTypeColor(event.type).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getEventTypeIcon(event.type),
              color: _getEventTypeColor(event.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('HH:mm').format(event.dateTime),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPriorityColor(event.priority),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _getPriorityText(event.priority),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.irrigation:
        return Colors.blue;
      case EventType.fertilization:
        return Colors.green;
      case EventType.pestControl:
        return Colors.red;
      case EventType.harvest:
        return Colors.orange;
      case EventType.soilAnalysis:
        return Colors.purple;
      case EventType.pruning:
        return Colors.brown;
    }
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.irrigation:
        return Icons.water_drop;
      case EventType.fertilization:
        return Icons.eco;
      case EventType.pestControl:
        return Icons.bug_report;
      case EventType.harvest:
        return Icons.agriculture;
      case EventType.soilAnalysis:
        return Icons.science;
      case EventType.pruning:
        return Icons.content_cut;
    }
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
    }
  }

  String _getPriorityText(Priority priority) {
    switch (priority) {
      case Priority.high:
        return 'Alta';
      case Priority.medium:
        return 'Media';
      case Priority.low:
        return 'Baja';
    }
  }
}


