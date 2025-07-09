// lib/ui/screens/home_screen_enhanced.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/report_model.dart';
import '../../core/services/report_service_enhanced.dart';
import '../widgets/custom_button.dart';
import 'create_report_enhanced.dart';
import 'login_screen.dart';

/// Pantalla principal mejorada con mejor manejo de errores
class HomeScreenEnhanced extends StatefulWidget {
  const HomeScreenEnhanced({super.key});

  @override
  State<HomeScreenEnhanced> createState() => _HomeScreenEnhancedState();
}

class _HomeScreenEnhancedState extends State<HomeScreenEnhanced>
    with TickerProviderStateMixin {
  List<ReportModel> _reports = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
  }

  void _setupAnimations() {
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _refreshAnimation = CurvedAnimation(
      parent: _refreshController,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadData() async {
    if (!_isLoading) {
      _refreshController.forward();
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reportService = ReportServiceEnhanced();

      // Verificar conexión primero
      final isConnected = await reportService.checkDatabaseHealth();
      if (!isConnected) {
        throw Exception('Sin conexión a la base de datos');
      }

      // Cargar datos en paralelo
      final results = await Future.wait([
        reportService.getMyReports(authProvider.currentUser!.id),
        reportService.getReportStats(authProvider.currentUser!.id),
      ]);

      setState(() {
        _reports = results[0] as List<ReportModel>;
        _stats = results[1] as Map<String, int>;
        _hasError = false;
      });

      print('✅ [HomeScreen] Datos cargados: ${_reports.length} reportes');

    } catch (e) {
      print('❌ [HomeScreen] Error cargando datos: $e');
      setState(() {
        _hasError = true;
        _errorMessage = _getErrorMessage(e.toString());
      });
    } finally {
      setState(() => _isLoading = false);
      if (_refreshController.isAnimating) {
        await _refreshController.reverse();
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('conexión') || error.contains('Network')) {
      return 'Error de conexión. Verifica tu internet.';
    } else if (error.contains('JWT') || error.contains('unauthorized')) {
      return 'Sesión expirada. Inicia sesión nuevamente.';
    } else {
      return 'Error cargando datos. Intenta nuevamente.';
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
          RotationTransition(
            turns: _refreshAnimation,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadData,
              tooltip: 'Actualizar',
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'logout':
                  _showLogoutDialog(context, authProvider);
                  break;
                case 'profile':
                  _showProfileInfo(context, user!);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Mi Perfil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildUserHeader(user!),
              if (_hasError) _buildErrorSection(),
              if (!_hasError) _buildStatsCards(),
              if (!_hasError) _buildReportsSection(),
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
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(int.parse(user.roleColor.replaceFirst('#', '0xFF'))),
                  child: Text(
                    user.fullName.split(' ').map((n) => n[0]).take(2).join(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${user.roleEmoji} ${user.roleDisplayName}',
                        style: const TextStyle(
                          color: Colors.white,
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

  Widget _buildErrorSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          const Text(
            'Error cargando datos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: CustomButton(
              text: 'Reintentar',
              icon: Icons.refresh,
              onPressed: _loadData,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: List.generate(3, (index) => 
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('📝', 'Borradores', _stats['borrador'] ?? 0, Colors.orange)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('📤', 'Enviados', _stats['enviado'] ?? 0, Colors.blue)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('✅', 'Aprobados', _stats['aprobado'] ?? 0, Colors.green)),
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              count.toString(),
              key: ValueKey('$label-$count'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
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
          Row(
            children: [
              const Text(
                'Mis Reportes Recientes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const Spacer(),
              if (_reports.isNotEmpty) ...[
                Text(
                  '${_reports.length} reportes',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            _buildLoadingList()
          else if (_reports.isEmpty)
            _buildEmptyState()
          else
            _buildReportsList(),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return Column(
      children: List.generate(3, (index) => 
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
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
    Color statusColor = Color(int.parse(report.statusColor.replaceFirst('#', '0xFF')));
    
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
          child: Text(
            _getTipoReporteEmoji(report.tipoReporte),
            style: const TextStyle(fontSize: 18),
          ),
        ),
        title: Text(
          report.empleadoInfo,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('📋 ${report.tipoReporteDisplayName}'),
            Text('📅 ${report.fechaHoraCompleta}'),
            const SizedBox(height: 4),
            Text(
              report.descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                report.statusDisplayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (report.esBorrador) ...[
              const SizedBox(height: 4),
              const Icon(Icons.edit, size: 16, color: Colors.grey),
            ],
          ],
        ),
        onTap: () => _handleReportTap(report),
      ),
    );
  }

  String _getTipoReporteEmoji(String tipo) {
    switch (tipo) {
      case 'falta': return '❌';
      case 'tardanza': return '⏰';
      case 'conducta': return '⚠️';
      default: return '📝';
    }
  }

  void _handleReportTap(ReportModel report) {
    if (report.esBorrador) {
      // Editar reporte
      _editReport(report);
    } else {
      // Ver detalles (próximamente)
      _viewReportDetails(report);
    }
  }

  Future<void> _editReport(ReportModel report) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReportEnhanced(existingReport: report),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _viewReportDetails(ReportModel report) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔍 Detalles del reporte (próximamente)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _navigateToCreateReport() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateReportEnhanced()),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _showProfileInfo(BuildContext context, user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mi Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${user.fullName}'),
            Text('Email: ${user.email}'),
            Text('Rol: ${user.roleDisplayName}'),
            if (user.department != null) Text('Departamento: ${user.department}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }
}