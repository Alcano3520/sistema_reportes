// lib/core/config/supabase_config.dart

import 'package:supabase_flutter/supabase_flutter.dart';

/// 🔧 Configuración de Supabase
/// Este archivo contiene la configuración para conectar con el backend
class SupabaseConfig {
  
  // 🔗 URL de tu proyecto Supabase
  static const String supabaseUrl = 'https://buzcapcwmksasrtjofae.supabase.co';
  
  // 🔑 Clave pública (anon key) - Segura para usar en Flutter
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1emNhcGN3bWtzYXNydGpvZmFlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5OTY4MzcsImV4cCI6MjA2NTU3MjgzN30.RjxEf5JmhoxfHL6QoncwHM5smQaoWq9ipVlrK_i2mPA';
  
  /// 🚀 Inicializar Supabase
  /// Llama este método al inicio de la aplicación
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true, // Solo para desarrollo
    );
  }
  
  /// 📦 Cliente de Supabase
  /// Acceso fácil al cliente desde cualquier parte de la app
  static SupabaseClient get client => Supabase.instance.client;
  
  /// 👤 Usuario actual
  /// Obtener el usuario autenticado actual
  static User? get currentUser => Supabase.instance.client.auth.currentUser;
  
  /// 📊 Estado de autenticación
  /// Verificar si hay un usuario logueado
  static bool get isAuthenticated => currentUser != null;
  
}