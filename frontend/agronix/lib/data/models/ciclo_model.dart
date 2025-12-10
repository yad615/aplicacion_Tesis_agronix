// lib/data/models/ciclo_model.dart

class CicloModel {
  final int id;
  final String cultivo;
  final String variedad;
  final String etapaActual;
  final DateTime etapaInicio;
  final String estado;
  final DateTime? fechaCierre;

  CicloModel({
    required this.id,
    required this.cultivo,
    required this.variedad,
    required this.etapaActual,
    required this.etapaInicio,
    required this.estado,
    this.fechaCierre,
  });

  factory CicloModel.fromJson(Map<String, dynamic> json) {
    return CicloModel(
      id: json['id'] as int,
      cultivo: json['cultivo'] as String,
      variedad: json['variedad'] as String,
      etapaActual: json['etapa_actual'] as String,
      etapaInicio: DateTime.parse(json['etapa_inicio'] as String),
      estado: json['estado'] as String,
      fechaCierre: json['fecha_cierre'] != null
          ? DateTime.parse(json['fecha_cierre'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cultivo': cultivo,
      'variedad': variedad,
      'etapa_actual': etapaActual,
      'etapa_inicio': etapaInicio.toIso8601String().split('T')[0],
      'estado': estado,
      'fecha_cierre': fechaCierre?.toIso8601String().split('T')[0],
    };
  }
}
