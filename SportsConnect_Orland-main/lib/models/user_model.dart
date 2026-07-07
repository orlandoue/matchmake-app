import 'package:orland_sports/enums/user_role.dart';

/// User model representing a user in the database
class UserModel {
  final String id;
  final String email;
  final String? name;
  final UserRole role;
  final String? profileImageUrl;
  final String? country;
  final String? dateOfBirth;
  final String? gender;
  final String? skillLevel;
  final String? favoritePosition;
  final bool isProfileComplete;
  final int balance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.role = UserRole.player,
    this.profileImageUrl,
    this.country,
    this.dateOfBirth,
    this.gender,
    this.skillLevel,
    this.favoritePosition,
    this.isProfileComplete = false,
    this.balance = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Create UserModel from JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'player'),
      profileImageUrl: json['profile_image_url'] as String?,
      country: json['country'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      skillLevel: json['skill_level'] as String?,
      favoritePosition: json['favorite_position'] as String?,
      isProfileComplete: json['is_profile_complete'] as bool? ?? false,
      balance: json['balance'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert UserModel to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.value,
      'profile_image_url': profileImageUrl,
      'country': country,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'skill_level': skillLevel,
      'favorite_position': favoritePosition,
      'is_profile_complete': isProfileComplete,
      'balance': balance,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? profileImageUrl,
    String? country,
    String? dateOfBirth,
    String? gender,
    String? skillLevel,
    String? favoritePosition,
    bool? isProfileComplete,
    int? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      country: country ?? this.country,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      skillLevel: skillLevel ?? this.skillLevel,
      favoritePosition: favoritePosition ?? this.favoritePosition,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, role: $role, isProfileComplete: $isProfileComplete)';
  }
}
