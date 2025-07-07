// lib/ui/widgets/employee_autocomplete.dart

import 'package:flutter/material.dart';
import '../../core/services/employee_service.dart';
import '../../core/models/empleado_model.dart';

/// Widget de autocompletado para buscar empleados - SIN DEPENDENCIAS EXTERNAS
class EmployeeAutocomplete extends StatefulWidget {
  final Function(EmpleadoModel) onSelected;
  final String? hint;

  const EmployeeAutocomplete({
    super.key,
    required this.onSelected,
    this.hint,
  });

  @override
  State<EmployeeAutocomplete> createState() => _EmployeeAutocompleteState();
}

class _EmployeeAutocompleteState extends State<EmployeeAutocomplete> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final EmployeeService _employeeService = EmployeeService();

  List<EmpleadoModel> _results = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    final query = _controller.text.trim();

    if (query.length < 2) {
      setState(() {
        _results = [];
        _showSuggestions = false;
      });
      return;
    }

    if (query != _lastQuery) {
      _lastQuery = query;
      _searchEmployees(query);
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Ocultar sugerencias después de un pequeño delay
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _showSuggestions = false;
          });
        }
      });
    }
  }

  Future<void> _searchEmployees(String query) async {
    setState(() {
      _isLoading = true;
      _showSuggestions = true;
    });

    try {
      final results = await _employeeService.searchEmployees(query);

      if (mounted && query == _lastQuery) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    }
  }

  void _selectEmployee(EmpleadoModel empleado) {
    _controller.text = empleado.nombresCompletos ?? 'Empleado ${empleado.cod}';
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.unfocus();
    widget.onSelected(empleado);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de búsqueda
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              labelText: 'Buscar empleado...',
              hintText: widget.hint ?? 'Nombre, cédula o código del empleado',
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF1E3A8A),
              ),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
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
                              _showSuggestions = false;
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
          ),
        ),

        // Lista de sugerencias
        if (_showSuggestions) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _buildSuggestionsList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestionsList() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Buscando empleados...'),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
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
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final empleado = _results[index];
        return _buildEmployeeCard(empleado);
      },
    );
  }

  Widget _buildEmployeeCard(EmpleadoModel empleado) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
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
        title: Text(
          empleado.nombresCompletos ?? 'Sin nombre',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _parseColor(empleado.estadoColor),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
        onTap: () => _selectEmployee(empleado),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6B7280);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
