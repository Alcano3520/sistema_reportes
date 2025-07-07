// lib/core/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// Provider de Autenticación
/// Maneja el estado global de login/logout y usuario actual
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Estados privados
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters públicos
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Constructor - Inicializa el listener de auth
  AuthProvider() {
    _initializeAuth();
  }

  /// Inicializar autenticación
  void _initializeAuth() {
    // Escuchar cambios en el estado de autenticación
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        _loadUserProfile();
      } else if (data.event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        notifyListeners();
      }
    });

    // Verificar si ya hay usuario logueado
    if (_supabase.auth.currentUser != null) {
      _loadUserProfile();
    }
  }

  /// Cargar perfil del usuario desde Supabase
  Future<void> _loadUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      _currentUser = UserModel.fromMap(response);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error cargando perfil: $e';
      notifyListeners();
    }
  }

  /// Iniciar sesión
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _getErrorMessage(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _supabase.auth.signOut();
      _currentUser = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al cerrar sesión: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Registrar nuevo usuario
  Future<bool> signUp(String email, String password, String fullName, String role) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Crear perfil en la tabla profiles
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'role': role,
        });

        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _getErrorMessage(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verificar si el usuario tiene un rol específico
  bool hasRole(String role) {
    return _currentUser?.role == role;
  }

  /// Verificar si es supervisor
  bool get isSupervisor => hasRole('supervisor');

  /// Verificar si es gerencia
  bool get isGerencia => hasRole('gerencia');

  /// Verificar si es RRHH
  bool get isRRHH => hasRole('rrhh');

  /// Establecer estado de carga
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Convertir errores técnicos a mensajes amigables
  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Email o contraseña incorrectos';
    } else if (error.contains('Email not confirmed')) {
      return 'Por favor confirma tu email antes de iniciar sesión';
    } else if (error.contains('Too many requests')) {
      return 'Demasiados intentos. Espera un momento e intenta de nuevo';
    } else if (error.contains('User already registered')) {
      return 'Este email ya está registrado';
    } else if (error.contains('Password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    } else if (error.contains('Unable to validate email address')) {
      return 'Email inválido';
    } else if (error.contains('Network request failed')) {
      return 'Error de conexión. Verifica tu internet';
    } else {
      return 'Error inesperado. Intenta de nuevo';
    }
  }

  /// Actualizar perfil del usuario
  Future<bool> updateProfile({
    String? fullName,
    String? department,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (department != null) updates['department'] = department;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', _currentUser!.id);

      // Actualizar el usuario local
      _currentUser = _currentUser!.copyWith(
        fullName: fullName ?? _currentUser!.fullName,
        department: department ?? _currentUser!.department,
        avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
      );

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error actualizando perfil: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refrescar datos del usuario
  Future<void> refreshUser() async {
    if (_supabase.auth.currentUser != null) {
      await _loadUserProfile();
    }
  }

  /// Limpiar todos los datos
  @override
  void dispose() {
    super.dispose();
  }
}