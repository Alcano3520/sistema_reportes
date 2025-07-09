// lib/core/services/employee_service_fixed.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/empleado_model.dart';

/// Servicio de empleados con debug y manejo robusto de errores
class EmployeeServiceFixed {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 🔍 Búsqueda principal de empleados con debug
  Future<List<EmpleadoModel>> searchEmployees(String query) async {
    print('🔍 [EmployeeService] Buscando: "$query"');
    
    try {
      if (query.length < 2) {
        print('⚠️ [EmployeeService] Query muy corto');
        return [];
      }

      // Construir la búsqueda paso a paso
      var queryBuilder = _supabase
          .from('empleados')
          .select('cod, cedula, nombres_completos, nomdep, fecha_ingreso, fecha_salida, es_activo')
          .eq('es_activo', true);

      // Buscar por diferentes campos
      List<Map<String, dynamic>> allResults = [];

      try {
        // 1. Buscar por nombres
        print('📝 [EmployeeService] Buscando por nombres...');
        final nameResults = await queryBuilder
            .ilike('nombres_completos', '%$query%')
            .limit(5);
        print('✅ [EmployeeService] Nombres encontrados: ${nameResults.length}');
        allResults.addAll(nameResults);
      } catch (e) {
        print('❌ [EmployeeService] Error buscando por nombres: $e');
      }

      try {
        // 2. Buscar por cédula
        print('🆔 [EmployeeService] Buscando por cédula...');
        final cedulaResults = await queryBuilder
            .ilike('cedula', '%$query%')
            .limit(5);
        print('✅ [EmployeeService] Cédulas encontradas: ${cedulaResults.length}');
        allResults.addAll(cedulaResults);
      } catch (e) {
        print('❌ [EmployeeService] Error buscando por cédula: $e');
      }

      // 3. Buscar por código si es número
      final numQuery = int.tryParse(query);
      if (numQuery != null) {
        try {
          print('🔢 [EmployeeService] Buscando por código: $numQuery');
          final codResults = await queryBuilder
              .eq('cod', numQuery)
              .limit(1);
          print('✅ [EmployeeService] Códigos encontrados: ${codResults.length}');
          allResults.addAll(codResults);
        } catch (e) {
          print('❌ [EmployeeService] Error buscando por código: $e');
        }
      }

      // Eliminar duplicados basado en el código
      final uniqueResults = <int, Map<String, dynamic>>{};
      for (var result in allResults) {
        final cod = result['cod'] as int;
        uniqueResults[cod] = result;
      }

      final finalResults = uniqueResults.values.toList();
      print('📊 [EmployeeService] Resultados únicos: ${finalResults.length}');

      // Convertir a modelos
      final empleados = finalResults
          .map<EmpleadoModel>((data) => EmpleadoModel.fromMap(data))
          .where((empleado) => empleado.isAvailableForReports)
          .toList();

      print('🎯 [EmployeeService] Empleados disponibles: ${empleados.length}');
      return empleados;

    } catch (e, stackTrace) {
      print('❌ [EmployeeService] ERROR GENERAL: $e');
      print('📍 [EmployeeService] Stack trace: $stackTrace');
      return [];
    }
  }

  /// 🧪 Probar conexión a Supabase
  Future<bool> testConnection() async {
    try {
      print('🧪 [EmployeeService] Probando conexión...');
      final response = await _supabase
          .from('empleados')
          .select('cod')
          .limit(1);
      
      print('✅ [EmployeeService] Conexión exitosa. Registros: ${response.length}');
      return true;
    } catch (e) {
      print('❌ [EmployeeService] Error de conexión: $e');
      return false;
    }
  }

  /// 📊 Obtener estadísticas para debug
  Future<Map<String, int>> getDebugStats() async {
    try {
      print('📊 [EmployeeService] Obteniendo estadísticas...');

      final total = await _supabase.from('empleados').select('cod');
      final activos = await _supabase.from('empleados').select('cod').eq('es_activo', true);
      final conNombres = await _supabase.from('empleados').select('cod').not('nombres_completos', 'is', null);
      final sinFechaSalida = await _supabase.from('empleados').select('cod').eq('es_activo', true).is_('fecha_salida', null);

      final stats = {
        'total': total.length,
        'activos': activos.length,
        'con_nombres': conNombres.length,
        'sin_fecha_salida': sinFechaSalida.length,
      };

      print('📈 [EmployeeService] Estadísticas: $stats');
      return stats;
    } catch (e) {
      print('❌ [EmployeeService] Error obteniendo estadísticas: $e');
      return {'total': 0, 'activos': 0, 'con_nombres': 0, 'sin_fecha_salida': 0};
    }
  }

  /// 🔍 Buscar empleado por código específico
  Future<EmpleadoModel?> getEmployeeByCode(int cod) async {
    try {
      print('🔍 [EmployeeService] Buscando empleado por código: $cod');
      
      final response = await _supabase
          .from('empleados')
          .select('cod, cedula, nombres_completos, nomdep, fecha_ingreso, fecha_salida, es_activo')
          .eq('cod', cod)
          .eq('es_activo', true)
          .maybeSingle();

      if (response != null) {
        print('✅ [EmployeeService] Empleado encontrado: ${response['nombres_completos']}');
        return EmpleadoModel.fromMap(response);
      } else {
        print('⚠️ [EmployeeService] Empleado no encontrado');
        return null;
      }
    } catch (e) {
      print('❌ [EmployeeService] Error buscando empleado: $e');
      return null;
    }
  }

  /// 📋 Validar que un empleado está disponible para reportes
  Future<bool> validateEmployee(int cod) async {
    try {
      final empleado = await getEmployeeByCode(cod);
      if (empleado == null) {
        print('❌ [EmployeeService] Empleado $cod no existe');
        return false;
      }

      if (!empleado.isAvailableForReports) {
        print('⚠️ [EmployeeService] Empleado $cod no disponible para reportes');
        return false;
      }

      print('✅ [EmployeeService] Empleado $cod válido para reportes');
      return true;
    } catch (e) {
      print('❌ [EmployeeService] Error validando empleado: $e');
      return false;
    }
  }

  /// 🏢 Obtener departamentos únicos
  Future<List<String>> getDepartments() async {
    try {
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
      print('🏢 [EmployeeService] Departamentos encontrados: ${departments.length}');
      return departments;
    } catch (e) {
      print('❌ [EmployeeService] Error obteniendo departamentos: $e');
      return [];
    }
  }
}