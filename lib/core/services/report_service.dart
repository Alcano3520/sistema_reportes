// lib/core/services/report_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_model.dart';
import '../models/empleado_model.dart';

/// Servicio para manejar reportes
class ReportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Crear un nuevo reporte
  Future<bool> createReport(ReportModel report) async {
    try {
      // Validar que el empleado existe y está activo
      final empleadoExists = await _validateEmployee(report.empleadoCod);
      if (!empleadoExists) {
        throw Exception(
            'El empleado con código ${report.empleadoCod} no existe o no está activo');
      }

      // Insertar el reporte
      await _supabase.from('reports').insert(report.toMap());

      return true;
    } catch (e) {
      print('Error creando reporte: $e');
      rethrow;
    }
  }

  /// Obtener reportes del supervisor actual
  Future<List<ReportModel>> getMyReports(String supervisorId) async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('supervisor_id', supervisorId)
          .order('created_at', ascending: false);

      return response
          .map<ReportModel>((data) => ReportModel.fromMap(data))
          .toList();
    } catch (e) {
      print('Error obteniendo reportes: $e');
      return [];
    }
  }

  /// Obtener un reporte específico por ID
  Future<ReportModel?> getReportById(String reportId) async {
    try {
      final response =
          await _supabase.from('reports').select().eq('id', reportId).single();

      return ReportModel.fromMap(response);
    } catch (e) {
      print('Error obteniendo reporte: $e');
      return null;
    }
  }

  /// Actualizar un reporte existente
  Future<bool> updateReport(ReportModel report) async {
    try {
      await _supabase
          .from('reports')
          .update(report.toMap())
          .eq('id', report.id);

      return true;
    } catch (e) {
      print('Error actualizando reporte: $e');
      return false;
    }
  }

  /// Cambiar estado de un reporte
  Future<bool> updateReportStatus(
    String reportId,
    String newStatus, {
    String? comentarios,
    String? reviewedBy,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (comentarios != null) {
        updates['comentarios_gerencia'] = comentarios;
      }

      if (reviewedBy != null) {
        updates['reviewed_by'] = reviewedBy;
        updates['fecha_revision'] = DateTime.now().toIso8601String();
      }

      await _supabase.from('reports').update(updates).eq('id', reportId);

      return true;
    } catch (e) {
      print('Error actualizando estado: $e');
      return false;
    }
  }

  /// Eliminar un reporte (solo borradores)
  Future<bool> deleteReport(String reportId) async {
    try {
      await _supabase
          .from('reports')
          .delete()
          .eq('id', reportId)
          .eq('status', 'borrador'); // Solo permitir eliminar borradores

      return true;
    } catch (e) {
      print('Error eliminando reporte: $e');
      return false;
    }
  }

  /// Obtener estadísticas de reportes
  Future<Map<String, int>> getReportStats(String supervisorId) async {
    try {
      // Obtener todos los reportes del supervisor
      final response = await _supabase
          .from('reports')
          .select('status')
          .eq('supervisor_id', supervisorId);

      // Contar por estado
      final stats = <String, int>{
        'total': response.length,
        'borrador': 0,
        'enviado': 0,
        'aprobado': 0,
        'rechazado': 0,
        'procesado': 0,
      };

      for (var report in response) {
        final status = report['status'] as String;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {
        'total': 0,
        'borrador': 0,
        'enviado': 0,
        'aprobado': 0,
        'rechazado': 0,
        'procesado': 0,
      };
    }
  }

  /// Obtener reportes por empleado
  Future<List<ReportModel>> getReportsByEmployee(int empleadoCod) async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('empleado_cod', empleadoCod)
          .order('fecha_incidente', ascending: false);

      return response
          .map<ReportModel>((data) => ReportModel.fromMap(data))
          .toList();
    } catch (e) {
      print('Error obteniendo reportes por empleado: $e');
      return [];
    }
  }

  /// Buscar reportes con filtros
  Future<List<ReportModel>> searchReports({
    String? supervisorId,
    String? tipoReporte,
    String? status,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? empleadoCod,
  }) async {
    try {
      var query = _supabase.from('reports').select();

      if (supervisorId != null) {
        query = query.eq('supervisor_id', supervisorId);
      }

      if (tipoReporte != null) {
        query = query.eq('tipo_reporte', tipoReporte);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      if (empleadoCod != null) {
        query = query.eq('empleado_cod', empleadoCod);
      }

      if (fechaDesde != null) {
        query = query.gte(
            'fecha_incidente', fechaDesde.toIso8601String().split('T')[0]);
      }

      if (fechaHasta != null) {
        query = query.lte(
            'fecha_incidente', fechaHasta.toIso8601String().split('T')[0]);
      }

      final response = await query.order('created_at', ascending: false);

      return response
          .map<ReportModel>((data) => ReportModel.fromMap(data))
          .toList();
    } catch (e) {
      print('Error buscando reportes: $e');
      return [];
    }
  }

  /// Validar que un empleado existe y está activo
  Future<bool> _validateEmployee(int empleadoCod) async {
    try {
      final response = await _supabase
          .from('empleados')
          .select('cod')
          .eq('cod', empleadoCod)
          .eq('es_activo', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error validando empleado: $e');
      return false;
    }
  }

  /// Obtener información del empleado para el reporte
  Future<EmpleadoModel?> getEmployeeInfo(int empleadoCod) async {
    try {
      final response = await _supabase
          .from('empleados')
          .select(
              'cod, cedula, nombres_completos, nomdep, fecha_ingreso, fecha_salida, es_activo')
          .eq('cod', empleadoCod)
          .eq('es_activo', true)
          .single();

      return EmpleadoModel.fromMap(response);
    } catch (e) {
      print('Error obteniendo info del empleado: $e');
      return null;
    }
  }

  /// Obtener reportes pendientes de revisión (para gerencia/RRHH)
  Future<List<ReportModel>> getPendingReports() async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('status', 'enviado')
          .order('created_at', ascending: true); // Los más antiguos primero

      return response
          .map<ReportModel>((data) => ReportModel.fromMap(data))
          .toList();
    } catch (e) {
      print('Error obteniendo reportes pendientes: $e');
      return [];
    }
  }

  /// Verificar si un supervisor puede editar un reporte
  bool canEditReport(ReportModel report, String currentUserId) {
    return report.supervisorId == currentUserId && report.status == 'borrador';
  }

  /// Enviar reporte (cambiar de borrador a enviado)
  Future<bool> submitReport(String reportId) async {
    return await updateReportStatus(reportId, 'enviado');
  }

  /// Aprobar reporte (para gerencia/RRHH)
  Future<bool> approveReport(String reportId, String reviewedBy,
      {String? comentarios}) async {
    return await updateReportStatus(
      reportId,
      'aprobado',
      comentarios: comentarios,
      reviewedBy: reviewedBy,
    );
  }

  /// Rechazar reporte (para gerencia/RRHH)
  Future<bool> rejectReport(
      String reportId, String reviewedBy, String comentarios) async {
    return await updateReportStatus(
      reportId,
      'rechazado',
      comentarios: comentarios,
      reviewedBy: reviewedBy,
    );
  }
}
