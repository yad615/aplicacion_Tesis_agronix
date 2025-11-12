// lib/domain/entities/user_entity.dart

class UserEntity {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? profileImage;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  UserEntity({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.profileImage,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  
  bool get isAdmin => role == 'admin';
  bool get isFarmer => role == 'farmer';
}
