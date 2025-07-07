// lib/ui/screens/create_report_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/empleado_model.dart';
import '../../core/models/report_model.dart';
import '../../core/services/report_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/employee_autocomplete.dart';

/// Pantalla para crear nuevos reportes
class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _testigosController = TextEditingController();

  // Variables del formulario
  String _tipoReporte = 'falta';
  DateTime _fechaIncidente = DateTime.now();
  TimeOfDay? _horaIncidente;
  EmpleadoModel? _empleadoSeleccionado;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _tiposReporte = [
    {
      'value': 'falta',
      'label': 'Falta',
      'icon': Icons.cancel,
      'color': Colors.red
    },
    {
      'value': 'tardanza',
      'label': 'Tardanza',
      'icon': Icons.access_time,
      'color': Colors.orange
    },
    {
      'value': 'conducta',
      'label': 'Conducta Inapropiada',
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
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección: Información del Empleado
              _buildSectionCard(
                title: '👤 Información del Empleado',
                child: Column(
                  children: [
                    EmployeeAutocomplete(
                      onSelected: (empleado) {
                        setState(() {
                          _empleadoSeleccionado = empleado;
                        });
                      },
                      hint: 'Buscar por nombre, cédula o código',
                    ),

                    // Mostrar info del empleado seleccionado
                    if (_empleadoSeleccionado != null) ...[
                      const SizedBox(height: 16),
                      _buildEmployeeInfo(),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sección: Detalles del Reporte
              _buildSectionCard(
                title: '📋 Detalles del Reporte',
                child: Column(
                  children: [
                    // Tipo de reporte
                    _buildTipoReporteSelector(),
                    const SizedBox(height: 16),

                    // Fecha y hora
                    _buildFechaHoraSelector(),
                    const SizedBox(height: 16),

                    // Descripción
                    CustomTextField(
                      controller: _descripcionController,
                      label: 'Descripción del incidente',
                      icon: Icons.description,
                      maxLines: 4,
                      hint: 'Describe detalladamente lo ocurrido...',
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'La descripción es obligatoria';
                        }
                        if (value!.length < 10) {
                          return 'La descripción debe tener al menos 10 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Ubicación (opcional)
                    CustomTextField(
                      controller: _ubicacionController,
                      label: 'Ubicación del incidente (opcional)',
                      icon: Icons.location_on,
                      hint: 'Ej: Área de producción, Oficinas, etc.',
                    ),
                    const SizedBox(height: 16),

                    // Testigos (opcional)
                    CustomTextField(
                      controller: _testigosController,
                      label: 'Testigos presentes (opcional)',
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

  Widget _buildSectionCard({required String title, required Widget child}) {
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

  Widget _buildEmployeeInfo() {
    final empleado = _empleadoSeleccionado!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
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
          const SizedBox(width: 16),

          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  empleado.nombresCompletos ?? 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (empleado.cedula != null) ...[
                  Text('CI: ${empleado.cedula}',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
                Text('Código: ${empleado.cod}',
                    style: TextStyle(color: Colors.grey.shade600)),
                if (empleado.nomDep != null) ...[
                  Text('${empleado.departmentEmoji} ${empleado.nomDep}',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ],
            ),
          ),

          // Botón para cambiar
          IconButton(
            onPressed: () {
              setState(() {
                _empleadoSeleccionado = null;
              });
            },
            icon: const Icon(Icons.edit, color: Color(0xFF1E3A8A)),
            tooltip: 'Cambiar empleado',
          ),
        ],
      ),
    );
  }

  Widget _buildTipoReporteSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de reporte',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 12),
        ...(_tiposReporte.map((tipo) {
          final isSelected = _tipoReporte == tipo['value'];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() => _tipoReporte = tipo['value']),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? tipo['color'].withValues(alpha: 0.1)
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
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tipo['label'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color:
                              isSelected ? tipo['color'] : Colors.grey.shade800,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: tipo['color'],
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList()),
      ],
    );
  }

  Widget _buildFechaHoraSelector() {
    return Row(
      children: [
        // Fecha
        Expanded(
          child: GestureDetector(
            onTap: _seleccionarFecha,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
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
                          'Fecha del incidente',
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
          ),
        ),

        const SizedBox(width: 12),

        // Hora
        Expanded(
          child: GestureDetector(
            onTap: _seleccionarHora,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFF1E3A8A)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hora (opcional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _horaIncidente?.format(context) ?? 'Seleccionar',
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
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Guardar como borrador
        Expanded(
          child: CustomOutlineButton(
            text: 'Guardar Borrador',
            icon: Icons.save,
            onPressed: _isLoading ? null : () => _guardarReporte('borrador'),
            isLoading: _isLoading,
          ),
        ),

        const SizedBox(width: 12),

        // Enviar reporte
        Expanded(
          child: CustomButton(
            text: 'Enviar Reporte',
            icon: Icons.send,
            onPressed: _isLoading ? null : () => _guardarReporte('enviado'),
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaIncidente,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );

    if (fecha != null) {
      setState(() => _fechaIncidente = fecha);
    }
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaIncidente ?? TimeOfDay.now(),
    );

    if (hora != null) {
      setState(() => _horaIncidente = hora);
    }
  }

  Future<void> _guardarReporte(String status) async {
    if (!_formKey.currentState!.validate()) return;

    if (_empleadoSeleccionado == null) {
      _mostrarError('Debe seleccionar un empleado');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reportService = ReportService();

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

      final success = await reportService.createReport(reporte);

      if (success && mounted) {
        Navigator.pop(context, true); // Retornar true para indicar éxito

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'borrador'
                  ? '✅ Borrador guardado correctamente'
                  : '📤 Reporte enviado correctamente',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _mostrarError('Error al guardar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $mensaje'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
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
    _descripcionController.dispose();
    _ubicacionController.dispose();
    _testigosController.dispose();
    super.dispose();
  }
}
