// Simple event bus for cross-screen communication
class CalendarEventBus {
  static final CalendarEventBus _instance = CalendarEventBus._internal();
  factory CalendarEventBus() => _instance;
  CalendarEventBus._internal();
  final List<void Function(CalendarEvent)> _listeners = [];
  void addListener(void Function(CalendarEvent) listener) => _listeners.add(listener);
  void removeListener(void Function(CalendarEvent) listener) => _listeners.remove(listener);
  void emit(CalendarEvent event) {
    for (final l in _listeners) l(event);
  }
}


enum EventType {
  irrigation,
  fertilization,
  pestControl,
  harvest,
  soilAnalysis,
  pruning,
}

enum Priority {
  high,
  medium,
  low,
}

class CalendarEvent {
    Map<String, dynamic> toJson() {
      return {
        'id': id,
        'title': title,
        'description': description,
        'date_time': dateTime.toIso8601String(),
        'type': type.toString().split('.').last,
        'priority': priority.toString().split('.').last,
        'origen': origen,
      };
    }
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final EventType type;
  final Priority priority;
  final String origen; // 'manual' o 'automatico'

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.type,
    required this.priority,
    required this.origen,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateTime: DateTime.parse(json['scheduled_date'] ?? json['date_time'] ?? DateTime.now().toIso8601String()),
      type: _parseEventType(json['task_type'] ?? json['type']),
      priority: _parsePriority(json['priority']),
      origen: json['origen'] ?? 'manual',
    );
  }

  static EventType _parseEventType(String? type) {
    switch (type?.toLowerCase()) {
      case 'irrigation':
      case 'riego':
        return EventType.irrigation;
      case 'fertilization':
      case 'fertilización':
        return EventType.fertilization;
      case 'pest_control':
      case 'control_plagas':
        return EventType.pestControl;
      case 'harvest':
      case 'cosecha':
        return EventType.harvest;
      case 'soil_analysis':
      case 'análisis_suelo':
        return EventType.soilAnalysis;
      case 'pruning':
      case 'poda':
        return EventType.pruning;
      default:
        return EventType.irrigation;
    }
  }

  static Priority _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
      case 'alta':
        return Priority.high;
      case 'medium':
      case 'media':
        return Priority.medium;
      case 'low':
      case 'baja':
        return Priority.low;
      default:
        return Priority.medium;
    }
  }
}
