// lib/models/user_model.dart

class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String role;
  final bool isActive;
  final String? profilePicture;
  final DateTime dateJoined;
  final DateTime? lastLogin;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.role,
    required this.isActive,
    this.profilePicture,
    required this.dateJoined,
    this.lastLogin,
  });

  // Verificar si es agricultor (único rol permitido en la app móvil)
  bool get isAgricultor => role == 'agricultor';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'agricultor',
      isActive: json['is_active'] == true || json['is_active'] == 'true',
      profilePicture: json['profile_picture']?.toString(),
      dateJoined: json['date_joined'] != null 
          ? DateTime.tryParse(json['date_joined'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastLogin: json['last_login'] != null 
          ? DateTime.tryParse(json['last_login'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'role': role,
      'is_active': isActive,
      'profile_picture': profilePicture,
      'date_joined': dateJoined.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName';
}

class AuthResponse {
  final String token;
  final UserModel user;
  final String? message;

  AuthResponse({
    required this.token,
    required this.user,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      message: json['message'] as String?,
    );
  }
}
