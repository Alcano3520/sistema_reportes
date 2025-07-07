// lib/core/services/employee_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/empleado_model.dart';

/// Servicio para buscar empleados - Solo campos necesarios
class EmployeeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Buscar empleados activos por nombre, cedula o código
  Future<List<EmpleadoModel>> searchEmployees(String query) async {
    try {
      if (query.length < 2) return [];

      // Solo seleccionar los campos que necesitamos
      final response = await _supabase
          .from('empleados')
          .select(
              'cod, cedula, nombres_completos, nomdep, fecha_ingreso, fecha_salida, es_activo')
          .eq('es_activo', true) // Solo empleados activos
          .or('nombres_completos.ilike.%$query%,cedula.ilike.%$query%,cod.eq.${_tryParseInt(query) ?? -1}')
          .isFilter('fecha_salida', null) // Sin fecha de salida
          .limit(10)
          .order('nombres_completos');

      return response
          .map<EmpleadoModel>((data) => EmpleadoModel.fromMap(data))
          .where((empleado) => empleado.isAvailableForReports)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Buscar empleado por código específico
  Future<EmpleadoModel?> getEmployeeByCode(int cod) async {
    try {
      final response = await _supabase
          .from('empleados')
          .select(
              'cod, cedula, nombres_completos, nomdep, fecha_ingreso, fecha_salida, es_activo')
          .eq('cod', cod)
          .eq('es_activo', true)
          .single();

      return EmpleadoModel.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Buscar empleado por cédula
  Future<EmpleadoModel?> getEmployeeByCedula(String cedula) async {
    try {
      final response = await _supabase
          .from('empleados')
          .select(
              'cod, cedula, nombres_completos, nomdep, fecha_ingreso, fecha_salida, es_activo')
          .eq('cedula', cedula)
          .eq('es_activo', true)
          .single();

      return EmpleadoModel.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Obtener empleados por departamento
  Future<List<EmpleadoModel>> getEmployeesByDepartment(
      String department) async {
    try {
      final response = await _supabase
          .from('empleados')
          .select(
              'cod, cedula, nombres_completos, nomdep, fecha_ingreso, fecha_salida, es_activo')
          .eq('nomdep', department)
          .eq('es_activo', true)
          .isFilter('fecha_salida', null) // Sin fecha de salida
          .order('nombres_completos')
          .limit(50);

      return response
          .map<EmpleadoModel>((data) => EmpleadoModel.fromMap(data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtener todos los departamentos únicos
  Future<List<String>> getDepartments() async {
    try {
      final response = await _supabase
          .from('empleados')
          .select('nomdep')
          .eq('es_activo', true)
          .not('nomdep', 'is', null);

      // Extraer departamentos únicos
      final departments = response
          .map<String>((data) => data['nomdep'] as String)
          .where((dep) => dep.isNotEmpty)
          .toSet()
          .toList();

      departments.sort();
      return departments;
    } catch (e) {
      return [];
    }
  }

  /// Obtener estadísticas básicas de empleados
  Future<Map<String, int>> getEmployeeStats() async {
    try {
      // Contar manualmente ya que la API de count ha cambiado
      final activeResponse = await _supabase
          .from('empleados')
          .select('cod')
          .eq('es_activo', true)
          .isFilter('fecha_salida', null);

      final withExitDateResponse = await _supabase
          .from('empleados')
          .select('cod')
          .eq('es_activo', true)
          .not('fecha_salida', 'is', null);

      final inactiveResponse = await _supabase
          .from('empleados')
          .select('cod')
          .eq('es_activo', false);

      return {
        'activos': activeResponse.length,
        'con_fecha_salida': withExitDateResponse.length,
        'inactivos': inactiveResponse.length,
        'total': activeResponse.length +
            withExitDateResponse.length +
            inactiveResponse.length,
      };
    } catch (e) {
      return {
        'activos': 0,
        'con_fecha_salida': 0,
        'inactivos': 0,
        'total': 0,
      };
    }
  }

  /// Validar que un empleado existe y está disponible
  Future<bool> validateEmployee(int cod) async {
    try {
      final empleado = await getEmployeeByCode(cod);
      return empleado != null && empleado.isAvailableForReports;
    } catch (e) {
      return false;
    }
  }

  /// Función auxiliar para convertir string a int
  int? _tryParseInt(String value) {
    try {
      return int.parse(value);
    } catch (e) {
      return null;
    }
  }

  /// Búsqueda rápida por nombre (para autocompletado rápido)
  Future<List<EmpleadoModel>> quickSearch(String query) async {
    try {
      if (query.length < 2) return [];

      final response = await _supabase
          .from('empleados')
          .select('cod, cedula, nombres_completos, nomdep')
          .eq('es_activo', true)
          .ilike('nombres_completos', '%$query%')
          .isFilter('fecha_salida', null)
          .limit(5)
          .order('nombres_completos');

      return response
          .map<EmpleadoModel>((data) => EmpleadoModel.fromMap(data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Verificar si un empleado tiene reportes previos
  Future<int> getEmployeeReportCount(int cod) async {
    try {
      final response =
          await _supabase.from('reports').select('id').eq('empleado_cod', cod);

      return response.length;
    } catch (e) {
      return 0;
    }
  }
}
