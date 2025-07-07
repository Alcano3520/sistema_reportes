// lib/ui/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/report_model.dart';
import '../../core/services/report_service.dart';
import '../widgets/custom_button.dart';
import 'create_report_screen.dart';
import 'login_screen.dart';

/// Pantalla principal del sistema
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ReportModel> _reports = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reportService = ReportService();

      // Cargar reportes y estadísticas en paralelo
      final results = await Future.wait([
        reportService.getMyReports(authProvider.currentUser!.id),
        reportService.getReportStats(authProvider.currentUser!.id),
      ]);

      setState(() {
        _reports = results[0] as List<ReportModel>;
        _stats = results[1] as Map<String, int>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Sistema de Reportes'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, authProvider),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header con información del usuario
              _buildUserHeader(user!),

              // Estadísticas
              _buildStatsCards(),

              // Lista de reportes
              _buildReportsSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateReport,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        label: const Text('Nuevo Reporte'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUserHeader(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar del usuario
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  user.fullName.split(' ').map((n) => n[0]).take(2).join(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Información del usuario
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bienvenido/a',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRoleColor(user.role).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getRoleColor(user.role)),
                      ),
                      child: Text(
                        _getRoleDisplayName(user.role),
                        style: TextStyle(
                          color: _getRoleColor(user.role),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
              child: _buildStatCard(
                  '📝', 'Borradores', _stats['borrador'] ?? 0, Colors.orange)),
          const SizedBox(width: 8),
          Expanded(
              child: _buildStatCard(
                  '📤', 'Enviados', _stats['enviado'] ?? 0, Colors.blue)),
          const SizedBox(width: 8),
          Expanded(
              child: _buildStatCard(
                  '✅', 'Aprobados', _stats['aprobado'] ?? 0, Colors.green)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String icon, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Reportes Recientes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_reports.isEmpty)
            _buildEmptyState()
          else
            _buildReportsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No tienes reportes aún',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crea tu primer reporte tocando el botón +',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: CustomButton(
              text: 'Crear Primer Reporte',
              icon: Icons.add,
              onPressed: _navigateToCreateReport,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return _buildReportCard(report);
      },
    );
  }

  Widget _buildReportCard(ReportModel report) {
    Color statusColor = _getStatusColor(report.status);
    IconData statusIcon = _getStatusIcon(report.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          report.empleadoNombresCompletos ?? 'Empleado ${report.empleadoCod}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
                '${_getTipoReporteEmoji(report.tipoReporte)} ${report.tipoReporteDisplayName}'),
            Text('📅 ${report.fechaIncidenteFormatted}'),
            if (report.empleadoDepartamento != null)
              Text('🏢 ${report.empleadoDepartamento}'),
            const SizedBox(height: 4),
            Text(
              report.descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            report.statusDisplayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () => _viewReportDetails(report),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'borrador':
        return Colors.orange;
      case 'enviado':
        return Colors.blue;
      case 'aprobado':
        return Colors.green;
      case 'rechazado':
        return Colors.red;
      case 'procesado':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'borrador':
        return Icons.edit;
      case 'enviado':
        return Icons.send;
      case 'aprobado':
        return Icons.check_circle;
      case 'rechazado':
        return Icons.cancel;
      case 'procesado':
        return Icons.inventory;
      default:
        return Icons.info;
    }
  }

  String _getTipoReporteEmoji(String tipo) {
    switch (tipo) {
      case 'falta':
        return '❌';
      case 'tardanza':
        return '⏰';
      case 'conducta':
        return '⚠️';
      default:
        return '📝';
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'supervisor':
        return Colors.blue;
      case 'gerencia':
        return Colors.purple;
      case 'rrhh':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'supervisor':
        return 'Supervisor';
      case 'gerencia':
        return 'Gerencia';
      case 'rrhh':
        return 'Recursos Humanos';
      default:
        return 'Usuario';
    }
  }

  Future<void> _navigateToCreateReport() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateReportScreen()),
    );

    if (result == true) {
      _loadData(); // Recargar datos si se creó un reporte
    }
  }

  void _viewReportDetails(ReportModel report) {
    // TODO: Implementar pantalla de detalles del reporte
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔍 Detalles del reporte (próximamente)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              },
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}
