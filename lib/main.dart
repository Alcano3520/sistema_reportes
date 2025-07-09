// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/supabase_config.dart';
import 'core/providers/auth_provider.dart';
import 'ui/screens/splash_screen.dart';

void main() async {
  try {
    // ⚡ Asegurar que Flutter esté inicializado
    WidgetsFlutterBinding.ensureInitialized();

    // 🔧 Inicializar Supabase
    print('🔧 Inicializando Supabase...');
    await SupabaseConfig.initialize();
    print('✅ Supabase inicializado correctamente');

    // 🚀 Ejecutar la aplicación
    runApp(const MyApp());
    
  } catch (e) {
    print('❌ Error inicializando la aplicación: $e');
    
    // En caso de error, mostrar pantalla de error
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Aquí se pueden agregar más providers en el futuro
      ],
      child: MaterialApp(
        title: 'Sistema de Reportes',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
          useMaterial3: true,
          
          // Configuración de tema personalizada
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E3A8A),
            brightness: Brightness.light,
          ),
          
          // AppBar theme
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Card theme
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          
          // Input decoration theme
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
            ),
          ),
        ),
        
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        
        // Configuración de localización (opcional)
        supportedLocales: const [
          Locale('es', 'ES'),
          Locale('en', 'US'),
        ],
      ),
    );
  }
}

/// Aplicación de error en caso de que falle la inicialización
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Error - Sistema de Reportes',
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de error
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red.shade600,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Título
                const Text(
                  'Error de Inicialización',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Mensaje de error
                Text(
                  'No se pudo inicializar la aplicación:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                // Error técnico
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sugerencias
                const Text(
                  'Sugerencias:\n'
                  '• Verifica tu conexión a internet\n'
                  '• Reinicia la aplicación\n'
                  '• Contacta al administrador si persiste',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Botón para reintentar (cierra la app)
                ElevatedButton(
                  onPressed: () {
                    // En una app real, aquí se podría reinicializar
                    // Por ahora, solo mostramos el mensaje
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Cerrar Aplicación'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}