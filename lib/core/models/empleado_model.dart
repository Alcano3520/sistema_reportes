// lib/core/models/empleado_model.dart

/// Modelo de Empleado Simplificado - Solo campos necesarios
class EmpleadoModel {
  final int cod;
  final String? cedula;
  final String? nombresCompletos;
  final String? nomDep;
  final String? fechaIngreso;
  final String? fechaSalida;
  final bool esActivo;

  EmpleadoModel({
    required this.cod,
    this.cedula,
    this.nombresCompletos,
    this.nomDep,
    this.fechaIngreso,
    this.fechaSalida,
    this.esActivo = true,
  });

  /// Crear desde datos de Supabase
  factory EmpleadoModel.fromMap(Map<String, dynamic> map) {
    return EmpleadoModel(
      cod: map['cod'] ?? 0,
      cedula: map['cedula'],
      nombresCompletos: map['nombres_completos'],
      nomDep: map['nomdep'],
      fechaIngreso: map['fecha_ingreso'],
      fechaSalida: map['fecha_salida'],
      esActivo: map['es_activo'] ?? true,
    );
  }

  /// Formato para mostrar en UI
  Map<String, dynamic> toDisplayMap() {
    return {
      'cod': cod,
      'cedula': cedula ?? '',
      'nombres_completos': nombresCompletos ?? 'Sin nombre',
      'nomdep': nomDep ?? 'Sin departamento',
      'display_text':
          '${nombresCompletos ?? 'Sin nombre'} - ${cedula ?? cod.toString()}',
      'subtitle': nomDep ?? 'Sin departamento',
      'es_activo': esActivo,
      'tiene_fecha_salida': fechaSalida != null && fechaSalida!.isNotEmpty,
    };
  }

  /// Verificar si coincide con la búsqueda
  bool matchesSearch(String query) {
    final queryLower = query.toLowerCase();

    return (nombresCompletos?.toLowerCase().contains(queryLower) ?? false) ||
        (cedula?.contains(queryLower) ?? false) ||
        cod.toString().contains(queryLower) ||
        (nomDep?.toLowerCase().contains(queryLower) ?? false);
  }

  /// Obtener iniciales del nombre
  String get initials {
    if (nombresCompletos == null || nombresCompletos!.isEmpty) {
      return 'NN';
    }

    final names = nombresCompletos!.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty && names[0].isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'NN';
  }

  /// Obtener color para avatar basado en el departamento
  String get departmentColor {
    if (nomDep == null) return '#6B7280';

    final dep = nomDep!.toLowerCase();
    switch (dep) {
      case 'producción':
      case 'produccion':
        return '#3B82F6'; // Azul
      case 'administración':
      case 'administracion':
        return '#8B5CF6'; // Púrpura
      case 'finanzas':
        return '#10B981'; // Verde
      case 'calidad':
        return '#F59E0B'; // Amarillo
      case 'mantenimiento':
        return '#EF4444'; // Rojo
      case 'recursos humanos':
      case 'rrhh':
        return '#06B6D4'; // Cian
      case 'sistemas':
      case 'it':
        return '#8B5CF6'; // Púrpura
      case 'ventas':
        return '#F97316'; // Naranja
      case 'compras':
        return '#84CC16'; // Lima
      default:
        return '#6B7280'; // Gris
    }
  }

  /// Obtener emoji según el departamento
  String get departmentEmoji {
    if (nomDep == null) return '📋';

    final dep = nomDep!.toLowerCase();
    switch (dep) {
      case 'producción':
      case 'produccion':
        return '🏭';
      case 'administración':
      case 'administracion':
        return '💼';
      case 'finanzas':
        return '💰';
      case 'calidad':
        return '✅';
      case 'mantenimiento':
        return '🔧';
      case 'recursos humanos':
      case 'rrhh':
        return '👥';
      case 'sistemas':
      case 'it':
        return '💻';
      case 'ventas':
        return '🛒';
      case 'compras':
        return '📦';
      default:
        return '📋';
    }
  }

  /// Verificar si el empleado está disponible para reportes
  bool get isAvailableForReports {
    // Activo y sin fecha de salida, o con fecha de salida futura/vacía
    return esActivo && (fechaSalida == null || fechaSalida!.isEmpty);
  }

  /// Obtener texto del estado del empleado
  String get estadoDisplay {
    if (!esActivo) return 'Inactivo';
    if (fechaSalida != null && fechaSalida!.isNotEmpty)
      return 'Con fecha de salida';
    return 'Activo';
  }

  /// Obtener color del estado
  String get estadoColor {
    if (!esActivo) return '#EF4444'; // Rojo
    if (fechaSalida != null && fechaSalida!.isNotEmpty)
      return '#F59E0B'; // Amarillo
    return '#10B981'; // Verde
  }

  /// Información completa para mostrar
  String get displayInfo {
    final info = StringBuffer();
    info.write(nombresCompletos ?? 'Sin nombre');

    if (cedula != null && cedula!.isNotEmpty) {
      info.write(' • CI: $cedula');
    }

    info.write(' • Cód: $cod');

    if (nomDep != null && nomDep!.isNotEmpty) {
      info.write(' • $nomDep');
    }

    return info.toString();
  }

  /// Convertir a String para debugging
  @override
  String toString() {
    return 'EmpleadoModel(cod: $cod, nombres: $nombresCompletos, cedula: $cedula, dep: $nomDep, activo: $esActivo)';
  }

  /// Comparar empleados por código
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmpleadoModel && other.cod == cod;
  }

  @override
  int get hashCode => cod.hashCode;
}
