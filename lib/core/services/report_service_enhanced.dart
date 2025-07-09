// lib/core/services/report_service_enhanced.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/report_model.dart';
import '../models/empleado_model.dart';
import 'employee_service_fixed.dart';

/// Servicio de reportes mejorado con validaciones completas
class ReportServiceEnhanced {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EmployeeServiceFixed _employeeService = EmployeeServiceFixed();

  /// ✅ Crear reporte con validaciones completas
  Future<ReportResult> createReport(ReportModel report) async {
    try {
      print('📝 [ReportService] Creando reporte para empleado ${report.empleadoCod}');

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

      // 3. Obtener información completa del empleado
      final empleado = await _employeeService.getEmployeeByCode(report.empleadoCod);
      if (empleado == null) {
        return ReportResult.error('No se pudo obtener información del empleado');
      }

      // 4. Crear reporte con información completa del empleado
      final reportWithEmployeeInfo = report.copyWith(
        empleadoNombresCompletos: empleado.nombresCompletos,
        empleadoCedula: empleado.cedula,
        empleadoDepartamento: empleado.nomDep,
      );

      // 5. Insertar en Supabase
      final data = reportWithEmployeeInfo.toMap();
      print('📤 [ReportService] Enviando datos: ${data.keys.join(', ')}');

      final response = await _supabase
          .from('reports')
          .insert(data)
          .select()
          .single();

      print('✅ [ReportService] Reporte creado exitosamente: ${response['id']}');

      return ReportResult.success(
        'Reporte ${report.status == 'borrador' ? 'guardado' : 'enviado'} exitosamente',
        ReportModel.fromMap(response),
      );

    } catch (e, stackTrace) {
      print('❌ [ReportService] Error creando reporte: $e');
      print('📍 [ReportService] Stack trace: $stackTrace');

      // Analizar tipo de error para dar mensajes específicos
      return ReportResult.error(_getErrorMessage(e.toString()));
    }
  }

  /// 🔍 Validar empleado existe y está activo
  Future<ValidationResult> _validateEmployee(int empleadoCod) async {
    try {
      final empleado = await _employeeService.getEmployeeByCode(empleadoCod);
      
      if (empleado == null) {
        return ValidationResult.invalid('Empleado con código $empleadoCod no encontrado');
      }

      if (!empleado.esActivo) {
        return ValidationResult.invalid('El empleado ${empleado.nombresCompletos} no está activo');
      }

      if (!empleado.isAvailableForReports) {
        return ValidationResult.invalid('El empleado ${empleado.nombresCompletos} no está disponible para reportes');
      }

      return ValidationResult.valid();

    } catch (e) {
      return ValidationResult.invalid('Error validando empleado: $e');
    }
  }

  /// ✅ Validar datos del reporte
  ValidationResult _validateReportData(ReportModel report) {
    // Validar descripción
    if (report.descripcion.trim().isEmpty) {
      return ValidationResult.invalid('La descripción es obligatoria');
    }

    if (report.descripcion.trim().length < 10) {
      return ValidationResult.invalid('La descripción debe tener al menos 10 caracteres');
    }

    if (report.descripcion.trim().length > 1000) {
      return ValidationResult.invalid('La descripción no puede exceder 1000 caracteres');
    }

    // Validar tipo de reporte
    if (!['falta', 'tardanza', 'conducta'].contains(report.tipoReporte)) {
      return ValidationResult.invalid('Tipo de reporte no válido');
    }

    // Validar fecha
    if (report.fechaIncidente.isAfter(DateTime.now())) {
      return ValidationResult.invalid('La fecha del incidente no puede ser futura');
    }

    final monthsAgo = DateTime.now().subtract(const Duration(days: 30));
    if (report.fechaIncidente.isBefore(monthsAgo)) {
      return ValidationResult.invalid('El incidente debe haber ocurrido en los últimos 30 días');
    }

    // Validar status
    if (!['borrador', 'enviado'].contains(report.status)) {
      return ValidationResult.invalid('Estado del reporte no válido');
    }

    // Validar ubicación (si existe)
    if (report.ubicacion != null && report.ubicacion!.length > 200) {
      return ValidationResult.invalid('La ubicación no puede exceder 200 caracteres');
    }

    // Validar testigos (si existe)
    if (report.testigos != null && report.testigos!.length > 500) {
      return ValidationResult.invalid('Los testigos no pueden exceder 500 caracteres');
    }

    return ValidationResult.valid();
  }

  /// 📊 Obtener reportes con información completa
  Future<List<ReportModel>> getMyReports(String supervisorId) async {
    try {
      print('📋 [ReportService] Obteniendo reportes para supervisor: $supervisorId');

      final response = await _supabase
          .from('reports')
          .select()
          .eq('supervisor_id', supervisorId)
          .order('created_at', ascending: false)
          .limit(50); // Limitar para rendimiento

      print('✅ [ReportService] Reportes encontrados: ${response.length}');

      return response
          .map<ReportModel>((data) => ReportModel.fromMap(data))
          .toList();

    } catch (e) {
      print('❌ [ReportService] Error obteniendo reportes: $e');
      return [];
    }
  }

  /// 📈 Estadísticas detalladas
  Future<Map<String, int>> getReportStats(String supervisorId) async {
    try {
      final reports = await getMyReports(supervisorId);

      final stats = <String, int>{
        'total': reports.length,
        'borrador': reports.where((r) => r.status == 'borrador').length,
        'enviado': reports.where((r) => r.status == 'enviado').length,
        'aprobado': reports.where((r) => r.status == 'aprobado').length,
        'rechazado': reports.where((r) => r.status == 'rechazado').length,
        'procesado': reports.where((r) => r.status == 'procesado').length,
        
        // Estadísticas por tipo
        'falta': reports.where((r) => r.tipoReporte == 'falta').length,
        'tardanza': reports.where((r) => r.tipoReporte == 'tardanza').length,
        'conducta': reports.where((r) => r.tipoReporte == 'conducta').length,
        
        // Estadísticas temporales
        'ultimo_mes': reports.where((r) => 
          r.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))
        ).length,
        'ultima_semana': reports.where((r) => 
          r.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7)))
        ).length,
      };

      print('📊 [ReportService] Estadísticas calculadas: $stats');
      return stats;

    } catch (e) {
      print('❌ [ReportService] Error obteniendo estadísticas: $e');
      return <String, int>{
        'total': 0, 'borrador': 0, 'enviado': 0, 'aprobado': 0, 
        'rechazado': 0, 'procesado': 0, 'falta': 0, 'tardanza': 0, 
        'conducta': 0, 'ultimo_mes': 0, 'ultima_semana': 0,
      };
    }
  }

  /// 📝 Actualizar reporte existente
  Future<ReportResult> updateReport(ReportModel report) async {
    try {
      // Solo permitir editar borradores
      if (report.status != 'borrador') {
        return ReportResult.error('Solo se pueden editar reportes en borrador');
      }

      // Validar datos
      final validation = _validateReportData(report);
      if (!validation.isValid) {
        return ReportResult.error(validation.message);
      }

      // Actualizar fecha de modificación
      final updatedReport = report.copyWith(updatedAt: DateTime.now());

      await _supabase
          .from('reports')
          .update(updatedReport.toMap())
          .eq('id', report.id);

      return ReportResult.success('Reporte actualizado exitosamente', updatedReport);

    } catch (e) {
      print('❌ [ReportService] Error actualizando reporte: $e');
      return ReportResult.error(_getErrorMessage(e.toString()));
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
          .eq('status', 'borrador'); // Solo permitir enviar borradores

      return ReportResult.success('Reporte enviado exitosamente', null);

    } catch (e) {
      print('❌ [ReportService] Error enviando reporte: $e');
      return ReportResult.error(_getErrorMessage(e.toString()));
    }
  }

  /// 🗑️ Eliminar reporte (solo borradores)
  Future<ReportResult> deleteReport(String reportId, String supervisorId) async {
    try {
      await _supabase
          .from('reports')
          .delete()
          .eq('id', reportId)
          .eq('supervisor_id', supervisorId)
          .eq('status', 'borrador'); // Solo permitir eliminar borradores

      return ReportResult.success('Reporte eliminado exitosamente', null);

    } catch (e) {
      print('❌ [ReportService] Error eliminando reporte: $e');
      return ReportResult.error(_getErrorMessage(e.toString()));
    }
  }

  /// 🔍 Obtener reporte por ID
  Future<ReportModel?> getReportById(String reportId) async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('id', reportId)
          .single();

      return ReportModel.fromMap(response);

    } catch (e) {
      print('❌ [ReportService] Error obteniendo reporte: $e');
      return null;
    }
  }

  /// 🔄 Verificar conexión y estado de base de datos
  Future<bool> checkDatabaseHealth() async {
    try {
      // Probar conexión básica
      await _supabase.from('reports').select('id').limit(1);
      
      // Probar conexión a empleados
      await _supabase.from('empleados').select('cod').limit(1);
      
      return true;
    } catch (e) {
      print('❌ [ReportService] Error de conexión: $e');
      return false;
    }
  }

  /// 📝 Convertir errores técnicos a mensajes amigables
  String _getErrorMessage(String error) {
    if (error.contains('foreign key')) {
      return 'El empleado seleccionado no es válido';
    } else if (error.contains('violates check constraint')) {
      return 'Los datos del reporte no cumplen con las reglas del sistema';
    } else if (error.contains('duplicate key')) {
      return 'Ya existe un reporte con este identificador';
    } else if (error.contains('Network request failed')) {
      return 'Error de conexión. Verifica tu internet e intenta nuevamente';
    } else if (error.contains('JWT')) {
      return 'Sesión expirada. Inicia sesión nuevamente';
    } else if (error.contains('permission')) {
      return 'No tienes permisos para realizar esta acción';
    } else {
      return 'Error inesperado. Intenta nuevamente o contacta al administrador';
    }
  }
}

// === CLASES DE APOYO ===

/// Resultado de operaciones de reporte
class ReportResult {
  final bool success;
  final String message;
  final ReportModel? report;

  ReportResult.success(this.message, this.report) : success = true;
  ReportResult.error(this.message) : success = false, report = null;
}

/// Resultado de validaciones
class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult.valid() : isValid = true, message = '';
  ValidationResult.invalid(this.message) : isValid = false;
}