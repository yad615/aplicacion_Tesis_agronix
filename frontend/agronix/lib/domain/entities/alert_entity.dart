// lib/domain/entities/alert_entity.dart

enum AlertType {
  critical,
  warning,
  info,
}

enum AlertCategory {
  temperature,
  humidity,
  conductivity,
  pest,
  weather,
  task,
}

class AlertEntity {
  final int id;
  final String title;
  final String message;
  final AlertType type;
  final AlertCategory category;
  final int? parcelaId;
  final bool isRead;
  final bool isDismissed;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? dismissedAt;

  AlertEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    this.parcelaId,
    required this.isRead,
    required this.isDismissed,
    required this.createdAt,
    this.readAt,
    this.dismissedAt,
  });

  bool get isActive => !isDismissed;
  bool get isUnread => !isRead;
  bool get isCritical => type == AlertType.critical;
}
