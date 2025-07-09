// lib/ui/widgets/employee_autocomplete_debug.dart

import 'package:flutter/material.dart';
import '../../core/services/employee_service_fixed.dart';
import '../../core/models/empleado_model.dart';

class EmployeeAutocompleteDebug extends StatefulWidget {
  final Function(EmpleadoModel) onSelected;
  final bool showDebugInfo;

  const EmployeeAutocompleteDebug({
    super.key,
    required this.onSelected,
    this.showDebugInfo = true,
  });

  @override
  State<EmployeeAutocompleteDebug> createState() => _EmployeeAutocompleteDebugState();
}

class _EmployeeAutocompleteDebugState extends State<EmployeeAutocompleteDebug> {
  final _controller = TextEditingController();
  final _service = EmployeeServiceFixed();
  
  List<EmpleadoModel> _results = [];
  bool _isLoading = false;
  String _debugInfo = '';
  bool _connectionTested = false;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    if (widget.showDebugInfo) {
      _initializeDebug();
    }
  }

  Future<void> _initializeDebug() async {
    setState(() {
      _debugInfo = '🔄 Inicializando...';
    });

    // Probar conexión
    final connected = await _service.testConnection();
    _connectionTested = true;

    // Obtener estadísticas
    final stats = await _service.getDebugStats();
    _stats = stats;

    setState(() {
      _debugInfo = '''
🔗 Conexión: ${connected ? '✅ OK' : '❌ ERROR'}
📊 Total empleados: ${stats['total'] ?? 0}
✅ Activos: ${stats['activos'] ?? 0}
📝 Con nombres: ${stats['con_nombres'] ?? 0}
🚫 Sin fecha salida: ${stats['sin_fecha_salida'] ?? 0}
''';
    });
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() {
        _results = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _service.searchEmployees(query);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      print('Error en búsqueda: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info de debug (si está habilitada)
        if (widget.showDebugInfo) ...[
          _buildDebugInfo(),
          const SizedBox(height: 16),
        ],

        // Campo de búsqueda
        _buildSearchField(),
        const SizedBox(height: 16),

        // Resultados
        _buildResults(),
      ],
    );
  }

  Widget _buildDebugInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Información de Debug',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Spacer(),
              if (!_connectionTested)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _debugInfo,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: Colors.blue,
            ),
          ),
          if (_connectionTested && _stats.isNotEmpty) ...[
            const Divider(),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  onPressed: _initializeDebug,
                  tooltip: 'Actualizar estadísticas',
                ),
                const Text('Actualizar', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
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
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: 'Buscar empleado',
          hintText: 'Nombre, cédula o código del empleado',
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF1E3A8A),
          ),
          suffixIcon: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _results = [];
                        });
                      },
                    )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        style: const TextStyle(fontSize: 16),
        onChanged: _search,
      ),
    );
  }

  Widget _buildResults() {
    if (_controller.text.length < 2) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey),
            SizedBox(width: 12),
            Text(
              'Escribe al menos 2 caracteres para buscar',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Buscando empleados...'),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange),
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.orange),
            const SizedBox(height: 12),
            const Text(
              'No se encontraron empleados',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Búsqueda: "${_controller.text}"',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifica que:\n• El empleado esté activo\n• El nombre esté bien escrito\n• No tenga fecha de salida',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final empleado = _results[index];
        return _buildEmployeeCard(empleado);
      },
    );
  }

  Widget _buildEmployeeCard(EmpleadoModel empleado) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          
          // Avatar con iniciales
          leading: CircleAvatar(
            backgroundColor: Color(int.parse(empleado.departmentColor.replaceFirst('#', '0xFF'))),
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

          // Información principal
          title: Text(
            empleado.nombresCompletos ?? 'Sin nombre',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Información secundaria
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
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
              Row(
                children: [
                  if (empleado.cedula != null && empleado.cedula!.isNotEmpty) ...[
                    Icon(Icons.badge_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'CI: ${empleado.cedula}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(Icons.numbers, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Cód: ${empleado.cod}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),

          // Estado e indicadores
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(int.parse(empleado.estadoColor.replaceFirst('#', '0xFF'))),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ),

          onTap: () {
            widget.onSelected(empleado);
            // Opcional: limpiar búsqueda después de seleccionar
            _controller.clear();
            setState(() {
              _results = [];
            });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}