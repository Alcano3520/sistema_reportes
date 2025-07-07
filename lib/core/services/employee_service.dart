// lib/core/services/employee_service_fixed.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/empleado_model.dart';

class EmployeeServiceFixed {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 🔍 Búsqueda de empleados con debug
  Future<List<EmpleadoModel>> searchEmployees(String query) async {
    print('🔍 Buscando empleados con query: "$query"');

    try {
      if (query.length < 2) {
        print('⚠️ Query muy corto');
        return [];
      }

      // Buscar por nombre
      final nameResponse = await _supabase
          .from('empleados')
          .select(
              'cod, cedula, nombres_completos, nomdep, fecha_ingreso, fecha_salida, es_activo')
          .eq('es_activo', true)
          .ilike('nombres_completos', '%$query%')
          .limit(5);

      print('✅ Respuesta nombres: ${nameResponse.length} resultados');

      // Buscar por cédula
      final cedulaResponse = await _supabase
          .from('empleados')
          .select(
              'cod, cedula, nombres_completos, nomdep, fecha_ingreso, fecha_salida, es_activo')
          .eq('es_activo', true)
          .ilike('cedula', '%$query%')
          .limit(5);

      print('✅ Respuesta cédulas: ${cedulaResponse.length} resultados');

      // Buscar por código si es número
      List<Map<String, dynamic>> codResponse = [];
      final numQuery = int.tryParse(query);
      if (numQuery != null) {
        codResponse = await _supabase
            .from('empleados')
            .select(
                'cod, cedula, nombres_completos, nomdep, fecha_ingreso, fecha_salida, es_activo')
            .eq('es_activo', true)
            .eq('cod', numQuery)
            .limit(5);

        print('✅ Respuesta códigos: ${codResponse.length} resultados');
      }

      // Combinar resultados únicos
      final allResults = <Map<String, dynamic>>[];
      final seenCods = <int>{};

      for (var result in [...nameResponse, ...cedulaResponse, ...codResponse]) {
        final cod = result['cod'] as int;
        if (!seenCods.contains(cod)) {
          seenCods.add(cod);
          allResults.add(result);
        }
      }

      print('📊 Total resultados únicos: ${allResults.length}');

      final empleados = allResults
          .map<EmpleadoModel>((data) => EmpleadoModel.fromMap(data))
          .where((empleado) => empleado.isAvailableForReports)
          .toList();

      print('🎯 Empleados disponibles: ${empleados.length}');

      return empleados;
    } catch (e, stackTrace) {
      print('❌ ERROR en búsqueda: $e');
      print('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  /// 🧪 Método de prueba para verificar conexión
  Future<bool> testConnection() async {
    try {
      print('🧪 Probando conexión a Supabase...');
      final response = await _supabase.from('empleados').select('cod').limit(1);

      print('✅ Conexión exitosa. Datos encontrados: ${response.length}');
      return true;
    } catch (e) {
      print('❌ Error de conexión: $e');
      return false;
    }
  }

  /// 📊 Obtener estadísticas para debug
  Future<Map<String, int>> getDebugStats() async {
    try {
      final total = await _supabase.from('empleados').select('cod');

      final activos =
          await _supabase.from('empleados').select('cod').eq('es_activo', true);

      final conNombres = await _supabase
          .from('empleados')
          .select('cod')
          .not('nombres_completos', 'is', null);

      return {
        'total': total.length,
        'activos': activos.length,
        'con_nombres': conNombres.length,
      };
    } catch (e) {
      print('Error obteniendo stats: $e');
      return {};
    }
  }

  /// 🔍 Validar empleado específico
  Future<EmpleadoModel?> getEmployeeByCode(int cod) async {
    try {
      print('🔍 Buscando empleado con código: $cod');

      final response = await _supabase
          .from('empleados')
          .select(
              'cod, cedula, nombres_completos, nomdep, fecha_ingreso, fecha_salida, es_activo')
          .eq('cod', cod)
          .eq('es_activo', true)
          .maybeSingle();

      if (response == null) {
        print('❌ Empleado no encontrado: $cod');
        return null;
      }

      final empleado = EmpleadoModel.fromMap(response);
      print('✅ Empleado encontrado: ${empleado.nombresCompletos}');

      return empleado;
    } catch (e) {
      print('❌ Error buscando empleado $cod: $e');
      return null;
    }
  }

  /// 📋 Obtener empleados por departamento
  Future<List<EmpleadoModel>> getEmployeesByDepartment(
      String department) async {
    try {
      print('🏢 Buscando empleados del departamento: $department');

      final response = await _supabase
          .from('empleados')
          .select(
              'cod, cedula, nombres_completos, nomdep, fecha_ingreso, fecha_salida, es_activo')
          .eq('nomdep', department)
          .eq('es_activo', true)
          .isFilter('fecha_salida', null)
          .order('nombres_completos')
          .limit(50);

      print('✅ Empleados encontrados en $department: ${response.length}');

      return response
          .map<EmpleadoModel>((data) => EmpleadoModel.fromMap(data))
          .toList();
    } catch (e) {
      print('❌ Error buscando empleados por departamento: $e');
      return [];
    }
  }

  /// 📊 Obtener todos los departamentos
  Future<List<String>> getDepartments() async {
    try {
      print('🏢 Obteniendo lista de departamentos...');

      final response = await _supabase
          .from('empleados')
          .select('nomdep')
          .eq('es_activo', true)
          .not('nomdep', 'is', null);

      final departments = response
          .map<String>((data) => data['nomdep'] as String)
          .where((dep) => dep.isNotEmpty)
          .toSet()
          .toList();

      departments.sort();
      print('✅ Departamentos encontrados: ${departments.length}');

      return departments;
    } catch (e) {
      print('❌ Error obteniendo departamentos: $e');
      return [];
    }
  }

  /// ✅ Validar que un empleado puede recibir reportes
  Future<ValidationResult> validateEmployeeForReport(int cod) async {
    try {
      print('🔍 Validando empleado $cod para reporte...');

      final empleado = await getEmployeeByCode(cod);

      if (empleado == null) {
        return ValidationResult(
          isValid: false,
          message: 'Empleado con código $cod no encontrado',
        );
      }

      if (!empleado.esActivo) {
        return ValidationResult(
          isValid: false,
          message: 'El empleado ${empleado.nombresCompletos} no está activo',
        );
      }

      if (empleado.fechaSalida != null && empleado.fechaSalida!.isNotEmpty) {
        return ValidationResult(
          isValid: false,
          message:
              'El empleado ${empleado.nombresCompletos} tiene fecha de salida',
        );
      }

      if (!empleado.isAvailableForReports) {
        return ValidationResult(
          isValid: false,
          message:
              'El empleado ${empleado.nombresCompletos} no está disponible para reportes',
        );
      }

      print('✅ Empleado válido para reportes');
      return ValidationResult(
        isValid: true,
        message: 'Empleado válido',
        empleado: empleado,
      );
    } catch (e) {
      print('❌ Error validando empleado: $e');
      return ValidationResult(
        isValid: false,
        message: 'Error validando empleado: $e',
      );
    }
  }

  /// 📈 Obtener estadísticas de reportes por empleado
  Future<int> getEmployeeReportCount(int cod) async {
    try {
      final response =
          await _supabase.from('reports').select('id').eq('empleado_cod', cod);

      return response.length;
    } catch (e) {
      print('Error obteniendo reportes del empleado $cod: $e');
      return 0;
    }
  }

  /// 🔍 Búsqueda rápida (solo nombres)
  Future<List<EmpleadoModel>> quickSearchByName(String query) async {
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
      print('Error en búsqueda rápida: $e');
      return [];
    }
  }
}

/// Clase para resultados de validación
class ValidationResult {
  final bool isValid;
  final String message;
  final EmpleadoModel? empleado;

  ValidationResult({
    required this.isValid,
    required this.message,
    this.empleado,
  });

  factory ValidationResult.valid({EmpleadoModel? empleado}) {
    return ValidationResult(
      isValid: true,
      message: 'Válido',
      empleado: empleado,
    );
  }

  factory ValidationResult.invalid(String message) {
    return ValidationResult(
      isValid: false,
      message: message,
    );
  }
}
