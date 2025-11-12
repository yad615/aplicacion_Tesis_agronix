import '../../domain/entities/task_entity.dart';

class TaskModel extends TaskEntity {
  TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.type,
    required super.priority,
    required super.status,
    required super.scheduledDate,
    super.completedDate,
    super.parcelaId,
    required super.isAiSuggested,
    required super.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      type: _parseTaskType(json['type']),
      priority: _parseTaskPriority(json['priority']),
      status: _parseTaskStatus(json['status']),
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      completedDate: json['completed_date'] != null
          ? DateTime.parse(json['completed_date'] as String)
          : null,
      parcelaId: json['parcela_id'] as int?,
      isAiSuggested: json['is_ai_suggested'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'scheduled_date': scheduledDate.toIso8601String(),
      'completed_date': completedDate?.toIso8601String(),
      'parcela_id': parcelaId,
      'is_ai_suggested': isAiSuggested,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TaskModel copyWith({
    int? id,
    String? title,
    String? description,
    TaskType? type,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? scheduledDate,
    DateTime? completedDate,
    int? parcelaId,
    bool? isAiSuggested,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      parcelaId: parcelaId ?? this.parcelaId,
      isAiSuggested: isAiSuggested ?? this.isAiSuggested,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static TaskType _parseTaskType(dynamic value) {
    if (value == null) return TaskType.irrigation;
    final str = value.toString().toLowerCase();
    return TaskType.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str,
      orElse: () => TaskType.irrigation,
    );
  }

  static TaskPriority _parseTaskPriority(dynamic value) {
    if (value == null) return TaskPriority.medium;
    final str = value.toString().toLowerCase();
    return TaskPriority.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str,
      orElse: () => TaskPriority.medium,
    );
  }

  static TaskStatus _parseTaskStatus(dynamic value) {
    if (value == null) return TaskStatus.pending;
    final str = value.toString().toLowerCase();
    return TaskStatus.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str,
      orElse: () => TaskStatus.pending,
    );
  }
}
