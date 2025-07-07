// lib/ui/widgets/employee_autocomplete.dart

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../core/services/employee_service.dart';
import '../../core/models/empleado_model.dart';

/// Widget de autocompletado para buscar empleados - Simplificado
class EmployeeAutocomplete extends StatelessWidget {
  final Function(EmpleadoModel) onSelected;
  final String? hint;

  const EmployeeAutocomplete({
    super.key,
    required this.onSelected,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TypeAheadField<EmpleadoModel>(
        builder: (context, controller, focusNode) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: 'Buscar empleado...',
              hintText: hint ?? 'Nombre, cédula o código del empleado',
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF1E3A8A),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 16),
          );
        },

        // Función de búsqueda
        suggestionsCallback: (pattern) async {
          if (pattern.length < 2) return [];

          try {
            return await EmployeeService().searchEmployees(pattern);
          } catch (e) {
            return [];
          }
        },

        // Cómo mostrar cada sugerencia
        itemBuilder: (context, empleado) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),

              // Avatar con iniciales y color del departamento
              leading: CircleAvatar(
                backgroundColor: _parseColor(empleado.departmentColor),
                radius: 25,
                child: Text(
                  empleado.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              // Nombre completo
              title: Text(
                empleado.nombresCompletos ?? 'Sin nombre',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Información del empleado
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // Departamento
                  if (empleado.nomDep != null && empleado.nomDep!.isNotEmpty)
                    Row(
                      children: [
                        Text(empleado.departmentEmoji),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            empleado.nomDep!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 4),

                  // Cédula y código
                  Row(
                    children: [
                      // Cédula
                      if (empleado.cedula != null &&
                          empleado.cedula!.isNotEmpty) ...[
                        Icon(
                          Icons.badge_outlined,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'CI: ${empleado.cedula}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],

                      // Código
                      Icon(
                        Icons.numbers,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Cód: ${empleado.cod}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // Fecha de ingreso (si existe)
                  if (empleado.fechaIngreso != null &&
                      empleado.fechaIngreso!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Ingreso: ${empleado.fechaIngreso}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              // Estado del empleado
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Indicador de estado
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _parseColor(empleado.estadoColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Flecha
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          );
        },

        // Qué hacer cuando selecciona un empleado
        onSelected: onSelected,

        // Configuración adicional
        hideOnEmpty: true,
        hideOnError: true,
        animationDuration: const Duration(milliseconds: 300),

        // Widget cuando está cargando
        loadingBuilder: (context) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'Buscando empleados...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },

        // Widget cuando no hay resultados
        emptyBuilder: (context) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No se encontraron empleados',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Intenta buscar por:\n• Nombre completo\n• Número de cédula\n• Código de empleado',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        },

        // Configuración de la caja de sugerencias
        decorationBuilder: (context, child) {
          return Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            child: child,
          );
        },
      ),
    );
  }

  /// Convertir string hex a Color
  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6B7280); // Gris por defecto
    }
  }
}
