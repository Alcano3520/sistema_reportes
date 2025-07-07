// lib/core/models/user_model.dart

/// 👤 Modelo de Usuario
/// Representa un usuario del sistema (Supervisor, Gerencia, RRHH)
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? department;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.department,
    this.avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// 🏭 Crear UserModel desde datos de Supabase
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      fullName: map['full_name'] ?? '',
      role: map['role'] ?? '',
      department: map['department'],
      avatarUrl: map['avatar_url'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.now(),
    );
  }

  /// 📦 Convertir UserModel a Map para Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'department': department,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 🔍 Verificaciones de rol
  bool get isSupervisor => role == 'supervisor';
  bool get isGerencia => role == 'gerencia';
  bool get isRRHH => role == 'rrhh';

  /// 📋 Obtener emoji según el rol
  String get roleEmoji {
    switch (role) {
      case 'supervisor':
        return '👥';
      case 'gerencia':
        return '💼';
      case 'rrhh':
        return '📊';
      default:
        return '👤';
    }
  }

  /// 📝 Obtener nombre del rol en español
  String get roleDisplayName {
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

  /// 🎨 Obtener color según el rol
  String get roleColor {
    switch (role) {
      case 'supervisor':
        return '#3B82F6'; // Azul
      case 'gerencia':
        return '#8B5CF6'; // Púrpura
      case 'rrhh':
        return '#10B981'; // Verde
      default:
        return '#6B7280'; // Gris
    }
  }

  /// 🔄 Crear copia con modificaciones
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? department,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      department: department ?? this.department,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 📄 Convertir a String para debugging
  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName, role: $role)';
  }

  /// ⚖️ Comparar usuarios
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}