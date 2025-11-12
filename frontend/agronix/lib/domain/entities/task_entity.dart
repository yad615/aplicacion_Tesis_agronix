// lib/domain/entities/task_entity.dart

enum TaskType {
  irrigation,
  fertilization,
  pestControl,
  harvest,
  soilAnalysis,
  pruning,
}

enum TaskPriority {
  low,
  medium,
  high,
}

enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

class TaskEntity {
  final int id;
  final String title;
  final String description;
  final TaskType type;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final int? parcelaId;
  final bool isAiSuggested;
  final DateTime createdAt;

  TaskEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.status,
    required this.scheduledDate,
    this.completedDate,
    this.parcelaId,
    required this.isAiSuggested,
    required this.createdAt,
  });

  bool get isCompleted => status == TaskStatus.completed;
  bool get isPending => status == TaskStatus.pending;
  bool get isOverdue => scheduledDate.isBefore(DateTime.now()) && !isCompleted;
  bool get isDueToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }
}
