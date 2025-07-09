// lib/ui/screens/splash_screen_updated.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/report_service_enhanced.dart';
import '../../core/services/employee_service_fixed.dart';
import 'login_screen.dart';
import 'home_screen_enhanced.dart';

/// Pantalla de splash mejorada con verificación de conexión
class SplashScreenUpdated extends StatefulWidget {
  const SplashScreenUpdated({super.key});

  @override
  State<SplashScreenUpdated> createState() => _SplashScreenUpdatedState();
}

class _SplashScreenUpdatedState extends State<SplashScreenUpdated>
    with TickerProviderStateMixin {
  
  // Controladores de animación
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;

  // Animaciones
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _textFade;
  late Animation<double> _progressValue;

  // Estado de la inicialización
  String _currentStep = 'Iniciando...';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startInitialization();
  }

  void _setupAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    // Progress animations
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startInitialization() async {
    try {
      // Iniciar animaciones
      _logoController.forward();
      await Future.delayed(const Duration(milliseconds: 500));
      _textController.forward();
      _progressController.forward();

      // Proceso de inicialización paso a paso
      await _initializeApp();

    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _currentStep = 'Error de inicialización';
      });
      
      // Esperar un poco antes de mostrar el error
      await Future.delayed(const Duration(seconds: 2));
      _showErrorDialog();
    }
  }

  Future<void> _initializeApp() async {
    // Paso 1: Verificar servicios
    setState(() => _currentStep = 'Verificando servicios...');
    await Future.delayed(const Duration(milliseconds: 800));
    
    final reportService = ReportServiceEnhanced();
    final employeeService = EmployeeServiceFixed();
    
    // Paso 2: Probar conexión a base de datos
    setState(() => _currentStep = 'Conectando a base de datos...');
    await Future.delayed(const Duration(milliseconds: 800));
    
    final dbHealthy = await reportService.checkDatabaseHealth();
    if (!dbHealthy) {
      throw Exception('No se pudo conectar a la base de datos');
    }

    // Paso 3: Verificar empleados
    setState(() => _currentStep = 'Verificando empleados...');
    await Future.delayed(const Duration(milliseconds: 600));
    
    final employeeConnected = await employeeService.testConnection();
    if (!employeeConnected) {
      throw Exception('No se pudo acceder a la información de empleados');
    }

    // Paso 4: Cargar estadísticas básicas
    setState(() => _currentStep = 'Cargando estadísticas...');
    await Future.delayed(const Duration(milliseconds: 600));
    
    final stats = await employeeService.getDebugStats();
    print('📊 Estadísticas de empleados: $stats');

    // Paso 5: Verificar autenticación
    setState(() => _currentStep = 'Verificando sesión...');
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Esperar a que termine la animación de progreso
    await _progressController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    // Navegación
    if (mounted) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    Widget nextScreen;
    if (authProvider.isAuthenticated) {
      nextScreen = const HomeScreenEnhanced();
    } else {
      nextScreen = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation.drive(
              Tween(begin: 0.0, end: 1.0).chain(
                CurveTween(curve: Curves.easeInOut),
              ),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _showErrorDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error de Inicialización'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('No se pudo inicializar la aplicación:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _errorMessage,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sugerencias:\n'
              '• Verifica tu conexión a internet\n'
              '• Asegúrate de que Supabase esté configurado\n'
              '• Revisa las credenciales en supabase_config.dart',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _retryInitialization();
            },
            child: const Text('Reintentar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToLoginAnyway();
            },
            child: const Text('Continuar sin conexión'),
          ),
        ],
      ),
    );
  }

  void _retryInitialization() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _currentStep = 'Reintentando...';
    });
    
    // Reiniciar animaciones
    _progressController.reset();
    _startInitialization();
  }

  void _navigateToLoginAnyway() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animado
              AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScale.value,
                    child: Transform.rotate(
                      angle: _logoRotation.value * 0.1,
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.assignment_outlined,
                          size: 80,
                          color: _hasError ? Colors.red : const Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Texto animado
              FadeTransition(
                opacity: _textFade,
                child: const Column(
                  children: [
                    Text(
                      'Sistema de Reportes',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Gestión profesional de incidencias',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // Barra de progreso animada
              if (!_hasError) ...[
                Container(
                  width: 250,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: AnimatedBuilder(
                    animation: _progressValue,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressValue.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.white, Colors.white70],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Texto de estado
                FadeTransition(
                  opacity: _textFade,
                  child: Text(
                    _currentStep,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ] else ...[
                // Indicador de error
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _currentStep,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Información de versión
              FadeTransition(
                opacity: _textFade,
                child: const Text(
                  'Versión 1.0.0 • Flutter + Supabase',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}