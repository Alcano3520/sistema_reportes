// lib/ui/widgets/employee_autocomplete_debug.dart

import 'package:flutter/material.dart';
import '../../core/services/employee_service_fixed.dart';
import '../../core/models/empleado_model.dart';

class EmployeeAutocompleteDebug extends StatefulWidget {
  final Function(EmpleadoModel) onSelected;

  const EmployeeAutocompleteDebug({
    super.key,
    required this.onSelected,
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

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    final connected = await _service.testConnection();
    final stats = await _service.getDebugStats();
    
    setState(() {
      _debugInfo = '''
🔗 Conexión: ${connected ? 'OK' : 'ERROR'}
📊 Empleados totales: ${stats['total'] ?? 0}
✅ Empleados activos: ${stats['activos'] ?? 0}
📝 Con nombres: ${stats['con_nombres'] ?? 0}
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

    final results = await _service.searchEmployees(query);
    
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Debug info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔧 Info de Debug:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_debugInfo),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Campo de búsqueda
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Buscar empleado',
            hintText: 'Nombre, cédula o código',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          onChanged: _search,
        ),

        const SizedBox(height: 16),

        // Resultados
        if (_results.isNotEmpty) ...[
          const Text(
            'Resultados:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final empleado = _results[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(empleado.initials),
                  ),
                  title: Text(empleado.nombresCompletos ?? 'Sin nombre'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Código: ${empleado.cod}'),
                      if (empleado.cedula != null) Text('CI: ${empleado.cedula}'),
                      if (empleado.nomDep != null) Text('Depto: ${empleado.nomDep}'),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => widget.onSelected(empleado),
                ),
              );
            },
          ),
        ] else if (_controller.text.length >= 2 && !_isLoading) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: const Column(
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.orange),
                SizedBox(height: 8),
                Text(
                  'No se encontraron empleados',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Verifica que existan empleados activos en la base de datos'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}