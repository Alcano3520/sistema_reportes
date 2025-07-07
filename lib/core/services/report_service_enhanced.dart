// lib/core/services/report_service_enhanced.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_model.dart';
import '../models/empleado_model.dart';

class ReportServiceEnhanced {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// ✅ Crear reporte con validaciones completas
  Future<ReportResult> createReport(ReportModel report) async {
    try {
      print('📝 Creando reporte para empleado ${report.empleadoCod}');

      // 1. Validar empleado
      final empleadoValid = await _validateEmployee(report.empleadoCod);
      if (!empleadoValid.isValid) {
        return ReportResult.error(empleadoValid.message);
      }

      // 2. Validar datos del reporte
      final validation = _validateReportData(report);
      if (!validation.isValid) {
        return ReportResult.error(validation.message);
      }

      // 3. Insertar en Supabase
      final data = report.toMap();
      print('📤 Enviando datos: $data');

      final response =
          await _supabase.from('reports').insert(data).select().single();

      print('✅ Reporte creado exitosamente: ${response['id']}');

      return ReportResult.success(
        'Reporte ${report.status == 'borrador' ? 'guardado' : 'enviado'} exitosamente',
        ReportModel.fromMap(response),
      );
    } catch (e, stackTrace) {
      print('❌ Error creando reporte: $e');
      print('📍 Stack trace: $stackTrace');

      // Analizar tipo de error
      if (e.toString().contains('foreign key')) {
        return ReportResult.error('El empleado seleccionado no es válido');
      } else if (e.toString().contains('violates check constraint')) {
        return ReportResult.error('Los datos del reporte no son válidos');
      } else {
        return ReportResult.error('Error de conexión. Intenta nuevamente');
      }
    }
  }

  /// 🔍 Validar empleado existe y está activo
  Future<ValidationResult> _validateEmployee(int empleadoCod) async {
    try {
      final response = await _supabase
          .from('empleados')
          .select('cod, nombres_completos, es_activo, fecha_salida')
          .eq('cod', empleadoCod)
          .maybeSingle();

      if (response == null) {
        return ValidationResult.invalid(
            'Empleado con código $empleadoCod no encontrado');
      }

      if (response['es_activo'] != true) {
        return ValidationResult.invalid(
            'El empleado ${response['nombres_completos']} no está activo');
      }

      if (response['fecha_salida'] != null) {
        return ValidationResult.invalid(
            'El empleado ${response['nombres_completos']} tiene fecha de salida');
      }

      return ValidationResult.valid();
    } catch (e) {
      return ValidationResult.invalid('Error validando empleado: $e');
    }
  }

  /// ✅ Validar datos del reporte
  ValidationResult _validateReportData(ReportModel report) {
    if (report.descripcion.trim().isEmpty) {
      return ValidationResult.invalid('La descripción es obligatoria');
    }

    if (report.descripcion.trim().length < 10) {
      return ValidationResult.invalid(
          'La descripción debe tener al menos 10 caracteres');
    }

    if (!['falta', 'tardanza', 'conducta'].contains(report.tipoReporte)) {
      return ValidationResult.invalid('Tipo de reporte no válido');
    }

    if (report.fechaIncidente.isAfter(DateTime.now())) {
      return ValidationResult.invalid(
          'La fecha del incidente no puede ser futura');
    }

    final monthsAgo = DateTime.now().subtract(const Duration(days: 30));
    if (report.fechaIncidente.isBefore(monthsAgo)) {
      return ValidationResult.invalid(
          'El incidente debe haber ocurrido en los últimos 30 días');
    }

    return ValidationResult.valid();
  }

  /// 📊 Obtener reportes con información completa
  Future<List<ReportModel>> getMyReports(String supervisorId) async {
    try {
      print('📋 Obteniendo reportes para supervisor: $supervisorId');

      final response = await _supabase
          .from('reports')
          .select()
          .eq('supervisor_id', supervisorId)
          .order('created_at', ascending: false);

      print('✅ Reportes encontrados: ${response.length}');

      return response
          .map<ReportModel>((data) => ReportModel.fromMap(data))
          .toList();
    } catch (e) {
      print('❌ Error obteniendo reportes: $e');
      return [];
    }
  }

  /// 📈 Estadísticas detalladas
  Future<ReportStats> getDetailedStats(String supervisorId) async {
    try {
      final reports = await getMyReports(supervisorId);

      final stats = ReportStats(
        total: reports.length,
        borradores: reports.where((r) => r.status == 'borrador').length,
        enviados: reports.where((r) => r.status == 'enviado').length,
        aprobados: reports.where((r) => r.status == 'aprobado').length,
        rechazados: reports.where((r) => r.status == 'rechazado').length,
        procesados: reports.where((r) => r.status == 'procesado').length,
        porTipo: {
          'falta': reports.where((r) => r.tipoReporte == 'falta').length,
          'tardanza': reports.where((r) => r.tipoReporte == 'tardanza').length,
          'conducta': reports.where((r) => r.tipoReporte == 'conducta').length,
        },
        ultimoReporte: reports.isNotEmpty ? reports.first.createdAt : null,
      );

      return stats;
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return ReportStats.empty();
    }
  }

  /// 🔄 Actualizar reporte existente
  Future<ReportResult> updateReport(ReportModel report) async {
    try {
      // Solo permitir actualizar borradores
      if (report.status != 'borrador') {
        return ReportResult.error('Solo se pueden editar reportes en borrador');
      }

      // Validar datos
      final validation = _validateReportData(report);
      if (!validation.isValid) {
        return ReportResult.error(validation.message);
      }

      final data = report.toMap();
      data['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('reports').update(data).eq('id', report.id);

      return ReportResult.success('Reporte actualizado exitosamente', report);
    } catch (e) {
      print('❌ Error actualizando reporte: $e');
      return ReportResult.error('Error actualizando reporte: $e');
    }
  }

  /// 📤 Enviar reporte (cambiar de borrador a enviado)
  Future<ReportResult> submitReport(String reportId) async {
    try {
      await _supabase
          .from('reports')
          .update({
            'status': 'enviado',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reportId)
          .eq('status', 'borrador'); // Solo si es borrador

      return ReportResult.success('Reporte enviado exitosamente', null);
    } catch (e) {
      return ReportResult.error('Error enviando reporte: $e');
    }
  }

  /// 🗑️ Eliminar reporte (solo borradores)
  Future<ReportResult> deleteReport(String reportId) async {
    try {
      await _supabase
          .from('reports')
          .delete()
          .eq('id', reportId)
          .eq('status', 'borrador');

      return ReportResult.success('Reporte eliminado exitosamente', null);
    } catch (e) {
      return ReportResult.error('Error eliminando reporte: $e');
    }
  }

  /// 📊 Obtener estadísticas básicas (para compatibilidad)
  Future<Map<String, int>> getReportStats(String supervisorId) async {
    try {
      final stats = await getDetailedStats(supervisorId);
      return {
        'total': stats.total,
        'borrador': stats.borradores,
        'enviado': stats.enviados,
        'aprobado': stats.aprobados,
        'rechazado': stats.rechazados,
        'procesado': stats.procesados,
      };
    } catch (e) {
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

  /// 🔍 Buscar reportes con filtros
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
}

// Clases de apoyo

class ReportResult {
  final bool success;
  final String message;
  final ReportModel? report;

  ReportResult.success(this.message, this.report) : success = true;
  ReportResult.error(this.message)
      : success = false,
        report = null;
}

class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult.valid()
      : isValid = true,
        message = '';
  ValidationResult.invalid(this.message) : isValid = false;
}

class ReportStats {
  final int total;
  final int borradores;
  final int enviados;
  final int aprobados;
  final int rechazados;
  final int procesados;
  final Map<String, int> porTipo;
  final DateTime? ultimoReporte;

  ReportStats({
    required this.total,
    required this.borradores,
    required this.enviados,
    required this.aprobados,
    required this.rechazados,
    required this.procesados,
    required this.porTipo,
    this.ultimoReporte,
  });

  factory ReportStats.empty() {
    return ReportStats(
      total: 0,
      borradores: 0,
      enviados: 0,
      aprobados: 0,
      rechazados: 0,
      procesados: 0,
      porTipo: {'falta': 0, 'tardanza': 0, 'conducta': 0},
    );
  }
}
