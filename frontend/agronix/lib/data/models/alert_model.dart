import '../../domain/entities/alert_entity.dart';

class AlertModel extends AlertEntity {
  AlertModel({
    required super.id,
    required super.title,
    required super.message,
    required super.type,
    required super.category,
    super.parcelaId,
    required super.isRead,
    required super.isDismissed,
    required super.createdAt,
    super.readAt,
    super.dismissedAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as int,
      title: json['title'] as String,
      message: json['message'] as String,
      type: _parseAlertType(json['type']),
      category: _parseAlertCategory(json['category']),
      parcelaId: json['parcela_id'] as int?,
      isRead: json['is_read'] as bool? ?? false,
      isDismissed: json['is_dismissed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      dismissedAt: json['dismissed_at'] != null
          ? DateTime.parse(json['dismissed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'category': category.toString().split('.').last,
      'parcela_id': parcelaId,
      'is_read': isRead,
      'is_dismissed': isDismissed,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'dismissed_at': dismissedAt?.toIso8601String(),
    };
  }

  AlertModel copyWith({
    int? id,
    String? title,
    String? message,
    AlertType? type,
    AlertCategory? category,
    int? parcelaId,
    bool? isRead,
    bool? isDismissed,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? dismissedAt,
  }) {
    return AlertModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      category: category ?? this.category,
      parcelaId: parcelaId ?? this.parcelaId,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      dismissedAt: dismissedAt ?? this.dismissedAt,
    );
  }

  static AlertType _parseAlertType(dynamic value) {
    if (value == null) return AlertType.info;
    final str = value.toString().toLowerCase();
    return AlertType.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str,
      orElse: () => AlertType.info,
    );
  }

  static AlertCategory _parseAlertCategory(dynamic value) {
    if (value == null) return AlertCategory.weather;
    final str = value.toString().toLowerCase();
    return AlertCategory.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str,
      orElse: () => AlertCategory.weather,
    );
  }
}
