// lib/ui/screens/create_report_enhanced.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/empleado_model.dart';
import '../../core/models/report_model.dart';
import '../../core/services/report_service_enhanced.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/employee_autocomplete_debug.dart';

class CreateReportEnhanced extends StatefulWidget {
  const CreateReportEnhanced({super.key});

  @override
  State<CreateReportEnhanced> createState() => _CreateReportEnhancedState();
}

class _CreateReportEnhancedState extends State<CreateReportEnhanced> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _testigosController = TextEditingController();

  String _tipoReporte = 'falta';
  DateTime _fechaIncidente = DateTime.now();
  TimeOfDay? _horaIncidente;
  EmpleadoModel? _empleadoSeleccionado;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showDebugInfo = false;

  final List<Map<String, dynamic>> _tiposReporte = [
    {
      'value': 'falta',
      'label': 'Falta Injustificada',
      'description': 'Ausencia sin justificación válida',
      'icon': Icons.cancel,
      'color': Colors.red
    },
    {
      'value': 'tardanza',
      'label': 'Tardanza',
      'description': 'Llegada tarde al puesto de trabajo',
      'icon': Icons.access_time,
      'color': Colors.orange
    },
    {
      'value': 'conducta',
      'label': 'Conducta Inapropiada',
      'description': 'Comportamiento inadecuado en el trabajo',
      'icon': Icons.warning,
      'color': Colors.amber
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Nuevo Reporte'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
                _showDebugInfo ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () {
              setState(() {
                _showDebugInfo = !_showDebugInfo;
              });
            },
            tooltip: 'Alternar info de debug',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mensaje de error global
              if (_errorMessage != null) ...[
                _buildErrorCard(),
                const SizedBox(height: 16),
              ],

              // Sección: Búsqueda de Empleado
              _buildSectionCard(
                title: '👤 Seleccionar Empleado',
                child: Column(
                  children: [
                    if (_showDebugInfo)
                      EmployeeAutocompleteDebug(
                        onSelected: (empleado) {
                          setState(() {
                            _empleadoSeleccionado = empleado;
                            _errorMessage = null;
                          });
                        },
                      )
                    else
                      // Widget normal de autocompletado aquí
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Activa el modo debug (🐛) para probar la búsqueda de empleados',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),

                    // Mostrar empleado seleccionado
                    if (_empleadoSeleccionado != null) ...[
                      const SizedBox(height: 16),
                      _buildSelectedEmployee(),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sección: Tipo de Reporte
              _buildSectionCard(
                title: '📋 Tipo de Incidente',
                child: _buildTipoReporteSelector(),
              ),

              const SizedBox(height: 16),

              // Sección: Detalles del Incidente
              _buildSectionCard(
                title: '📝 Detalles del Incidente',
                child: Column(
                  children: [
                    // Fecha y hora
                    _buildDateTimeSection(),
                    const SizedBox(height: 16),

                    // Descripción
                    CustomTextField(
                      controller: _descripcionController,
                      label: 'Descripción detallada del incidente *',
                      icon: Icons.description,
                      maxLines: 5,
                      hint:
                          'Describe lo ocurrido con el mayor detalle posible...',
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'La descripción es obligatoria';
                        }
                        if (value!.length < 10) {
                          return 'Mínimo 10 caracteres';
                        }
                        if (value.length > 1000) {
                          return 'Máximo 1000 caracteres';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Ubicación
                    CustomTextField(
                      controller: _ubicacionController,
                      label: 'Ubicación del incidente',
                      icon: Icons.location_on,
                      hint: 'Ej: Área de producción, Oficina principal, etc.',
                    ),

                    const SizedBox(height: 16),

                    // Testigos
                    CustomTextField(
                      controller: _testigosController,
                      label: 'Testigos presentes',
                      icon: Icons.people,
                      maxLines: 2,
                      hint: 'Nombres de personas que presenciaron el incidente',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botones de acción
              _buildActionButtons(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedEmployee() {
    final empleado = _empleadoSeleccionado!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green,
            child: Text(
              empleado.initials,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  empleado.nombresCompletos ?? 'Sin nombre',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (empleado.cedula != null) Text('CI: ${empleado.cedula}'),
                Text('Código: ${empleado.cod}'),
                if (empleado.nomDep != null) Text('Depto: ${empleado.nomDep}'),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.green),
            onPressed: () {
              setState(() {
                _empleadoSeleccionado = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTipoReporteSelector() {
    return Column(
      children: _tiposReporte.map((tipo) {
        final isSelected = _tipoReporte == tipo['value'];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => setState(() => _tipoReporte = tipo['value']),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? tipo['color'].withOpacity(0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? tipo['color'] : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    tipo['icon'],
                    color: isSelected ? tipo['color'] : Colors.grey.shade600,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tipo['label'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? tipo['color']
                                : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tipo['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: tipo['color'],
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fecha y hora del incidente',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildDateSelector(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeSelector(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _seleccionarFecha,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF1E3A8A)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha *',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_fechaIncidente.day}/${_fechaIncidente.month}/${_fechaIncidente.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return GestureDetector(
      onTap: _seleccionarHora,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Color(0xFF1E3A8A)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hora',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _horaIncidente?.format(context) ?? 'Opcional',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _horaIncidente != null
                          ? Colors.black87
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Info sobre los botones
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Borrador: Guarda para continuar después\nEnviar: Envía a revisión (no se puede editar)',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Botones
        Row(
          children: [
            Expanded(
              child: CustomOutlineButton(
                text: 'Guardar Borrador',
                icon: Icons.save,
                onPressed:
                    _isLoading ? null : () => _guardarReporte('borrador'),
                isLoading: _isLoading,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Enviar Reporte',
                icon: Icons.send,
                onPressed: _isLoading ? null : () => _guardarReporte('enviado'),
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _seleccionarFecha() async {
    final now = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaIncidente,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
      locale: const Locale('es', 'ES'),
      helpText: 'Seleccionar fecha del incidente',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (fecha != null) {
      setState(() => _fechaIncidente = fecha);
    }
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaIncidente ?? TimeOfDay.now(),
      helpText: 'Seleccionar hora del incidente',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );

    if (hora != null) {
      setState(() => _horaIncidente = hora);
    }
  }

  Future<void> _guardarReporte(String status) async {
    // Limpiar error anterior
    setState(() {
      _errorMessage = null;
    });

    // Validaciones básicas
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_empleadoSeleccionado == null) {
      setState(() {
        _errorMessage = 'Debe seleccionar un empleado';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reportService = ReportServiceEnhanced();

      final reporte = ReportModel(
        supervisorId: authProvider.currentUser!.id,
        empleadoCod: _empleadoSeleccionado!.cod,
        empleadoNombresCompletos: _empleadoSeleccionado!.nombresCompletos,
        empleadoCedula: _empleadoSeleccionado!.cedula,
        empleadoDepartamento: _empleadoSeleccionado!.nomDep,
        tipoReporte: _tipoReporte,
        descripcion: _descripcionController.text.trim(),
        fechaIncidente: _fechaIncidente,
        horaIncidente: _horaIncidente?.format(context),
        ubicacion: _ubicacionController.text.trim().isEmpty
            ? null
            : _ubicacionController.text.trim(),
        testigos: _testigosController.text.trim().isEmpty
            ? null
            : _testigosController.text.trim(),
        status: status,
      );

      final result = await reportService.createReport(reporte);

      if (result.success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result.message}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error inesperado: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _testigosController.dispose();
    super.dispose();
  }
}
