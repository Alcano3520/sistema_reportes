// lib/core/models/report_model.dart

import 'package:uuid/uuid.dart';

/// Modelo de Reporte - Actualizado para tabla real de empleados
class ReportModel {
  final String id;
  final String supervisorId;
  final int empleadoCod;
  final String? empleadoNombresCompletos;
  final String? empleadoCedula;
  final String? empleadoDepartamento;
  final String tipoReporte;
  final String descripcion;
  final DateTime fechaIncidente;
  final String? horaIncidente;
  final String? ubicacion;
  final String? testigos;
  final String? fotoUrl;
  final String? firmaPath;
  final String status;
  final String? comentariosGerencia;
  final String? comentariosRRHH;
  final DateTime? fechaRevision;
  final String? reviewedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportModel({
    String? id,
    required this.supervisorId,
    required this.empleadoCod,
    this.empleadoNombresCompletos,
    this.empleadoCedula,
    this.empleadoDepartamento,
    required this.tipoReporte,
    required this.descripcion,
    required this.fechaIncidente,
    this.horaIncidente,
    this.ubicacion,
    this.testigos,
    this.fotoUrl,
    this.firmaPath,
    this.status = 'borrador',
    this.comentariosGerencia,
    this.comentariosRRHH,
    this.fechaRevision,
    this.reviewedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Crear ReportModel desde datos de Supabase
  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] ?? const Uuid().v4(),
      supervisorId: map['supervisor_id'] ?? '',
      empleadoCod: map['empleado_cod'] ?? 0,
      empleadoNombresCompletos: map['empleado_nombres_completos'],
      empleadoCedula: map['empleado_cedula'],
      empleadoDepartamento: map['empleado_departamento'],
      tipoReporte: map['tipo_reporte'] ?? '',
      descripcion: map['descripcion'] ?? '',
      fechaIncidente: map['fecha_incidente'] != null
          ? DateTime.parse(map['fecha_incidente'])
          : DateTime.now(),
      horaIncidente: map['hora_incidente'],
      ubicacion: map['ubicacion'],
      testigos: map['testigos'],
      fotoUrl: map['foto_url'],
      firmaPath: map['firma_supervisor'],
      status: map['status'] ?? 'borrador',
      comentariosGerencia: map['comentarios_gerencia'],
      comentariosRRHH: map['comentarios_rrhh'],
      fechaRevision: map['fecha_revision'] != null
          ? DateTime.parse(map['fecha_revision'])
          : null,
      reviewedBy: map['reviewed_by'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
    );
  }

  /// Convertir ReportModel a Map para Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supervisor_id': supervisorId,
      'empleado_cod': empleadoCod,
      // Los campos de empleado se llenan automáticamente por el trigger
      'tipo_reporte': tipoReporte,
      'descripcion': descripcion,
      'fecha_incidente': fechaIncidente.toIso8601String().split('T')[0],
      'hora_incidente': horaIncidente,
      'ubicacion': ubicacion,
      'testigos': testigos,
      'foto_url': fotoUrl,
      'firma_supervisor': firmaPath,
      'status': status,
      'comentarios_gerencia': comentariosGerencia,
      'comentarios_rrhh': comentariosRRHH,
      'fecha_revision': fechaRevision?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convertir para base de datos local (SQLite)
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'supervisor_id': supervisorId,
      'empleado_cod': empleadoCod,
      'empleado_nombres_completos': empleadoNombresCompletos ?? '',
      'empleado_cedula': empleadoCedula ?? '',
      'empleado_departamento': empleadoDepartamento ?? '',
      'tipo_reporte': tipoReporte,
      'descripcion': descripcion,
      'fecha_incidente': fechaIncidente.toIso8601String().split('T')[0],
      'hora_incidente': horaIncidente,
      'ubicacion': ubicacion,
      'testigos': testigos,
      'foto_path': fotoUrl,
      'firma_path': firmaPath,
      'status': status,
      'is_synced': 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Obtener color segun el estado
  String get statusColor {
    switch (status) {
      case 'borrador':
        return '#F59E0B';
      case 'enviado':
        return '#3B82F6';
      case 'aprobado':
        return '#10B981';
      case 'rechazado':
        return '#EF4444';
      case 'procesado':
        return '#8B5CF6';
      default:
        return '#6B7280';
    }
  }

  /// Obtener nombre del estado en español
  String get statusDisplayName {
    switch (status) {
      case 'borrador':
        return 'Borrador';
      case 'enviado':
        return 'Enviado';
      case 'aprobado':
        return 'Aprobado';
      case 'rechazado':
        return 'Rechazado';
      case 'procesado':
        return 'Procesado';
      default:
        return 'Desconocido';
    }
  }

  /// Obtener nombre del tipo en español
  String get tipoReporteDisplayName {
    switch (tipoReporte) {
      case 'falta':
        return 'Falta';
      case 'tardanza':
        return 'Tardanza';
      case 'conducta':
        return 'Conducta Inapropiada';
      default:
        return tipoReporte;
    }
  }

  /// Formatear fecha de incidente
  String get fechaIncidenteFormatted {
    return '${fechaIncidente.day.toString().padLeft(2, '0')}/'
        '${fechaIncidente.month.toString().padLeft(2, '0')}/'
        '${fechaIncidente.year}';
  }

  /// Formatear fecha y hora completa
  String get fechaHoraCompleta {
    String fecha = fechaIncidenteFormatted;
    if (horaIncidente != null && horaIncidente!.isNotEmpty) {
      return '$fecha a las $horaIncidente';
    }
    return fecha;
  }

  /// Verificaciones de estado
  bool get esBorrador => status == 'borrador';
  bool get esEnviado => status == 'enviado';
  bool get esAprobado => status == 'aprobado';
  bool get esRechazado => status == 'rechazado';
  bool get esProcesado => status == 'procesado';

  /// Verificar si tiene evidencias
  bool get tieneEvidencias {
    return (fotoUrl != null && fotoUrl!.isNotEmpty) ||
        (firmaPath != null && firmaPath!.isNotEmpty);
  }

  /// Obtener información del empleado
  String get empleadoInfo {
    final info = StringBuffer();

    if (empleadoNombresCompletos != null &&
        empleadoNombresCompletos!.isNotEmpty) {
      info.write(empleadoNombresCompletos!);
    } else {
      info.write('Empleado $empleadoCod');
    }

    if (empleadoCedula != null && empleadoCedula!.isNotEmpty) {
      info.write(' (CI: $empleadoCedula)');
    }

    if (empleadoDepartamento != null && empleadoDepartamento!.isNotEmpty) {
      info.write(' - $empleadoDepartamento');
    }

    return info.toString();
  }

  /// Crear copia con modificaciones
  ReportModel copyWith({
    String? id,
    String? supervisorId,
    int? empleadoCod,
    String? empleadoNombresCompletos,
    String? empleadoCedula,
    String? empleadoDepartamento,
    String? tipoReporte,
    String? descripcion,
    DateTime? fechaIncidente,
    String? horaIncidente,
    String? ubicacion,
    String? testigos,
    String? fotoUrl,
    String? firmaPath,
    String? status,
    String? comentariosGerencia,
    String? comentariosRRHH,
    DateTime? fechaRevision,
    String? reviewedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      supervisorId: supervisorId ?? this.supervisorId,
      empleadoCod: empleadoCod ?? this.empleadoCod,
      empleadoNombresCompletos:
          empleadoNombresCompletos ?? this.empleadoNombresCompletos,
      empleadoCedula: empleadoCedula ?? this.empleadoCedula,
      empleadoDepartamento: empleadoDepartamento ?? this.empleadoDepartamento,
      tipoReporte: tipoReporte ?? this.tipoReporte,
      descripcion: descripcion ?? this.descripcion,
      fechaIncidente: fechaIncidente ?? this.fechaIncidente,
      horaIncidente: horaIncidente ?? this.horaIncidente,
      ubicacion: ubicacion ?? this.ubicacion,
      testigos: testigos ?? this.testigos,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      firmaPath: firmaPath ?? this.firmaPath,
      status: status ?? this.status,
      comentariosGerencia: comentariosGerencia ?? this.comentariosGerencia,
      comentariosRRHH: comentariosRRHH ?? this.comentariosRRHH,
      fechaRevision: fechaRevision ?? this.fechaRevision,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convertir a String para debugging
  @override
  String toString() {
    return 'ReportModel(id: $id, empleado: ${empleadoNombresCompletos ?? empleadoCod}, tipo: $tipoReporte, status: $status)';
  }

  /// Comparar reportes
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
