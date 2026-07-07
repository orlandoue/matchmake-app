import 'package:flutter/material.dart';

/// Sport model representing a sport that can be played at courts
class SportModel {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SportModel({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Create SportModel from JSON map
  factory SportModel.fromJson(Map<String, dynamic> json) {
    return SportModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert SportModel to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy of SportModel with updated fields
  SportModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SportModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get the icon for the sport based on iconUrl identifier
  IconData get icon {
    switch (iconUrl) {
      case 'sports_tennis':
        return Icons.sports_tennis;
      case 'sports_basketball':
        return Icons.sports_basketball;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'sports_volleyball':
        return Icons.sports_volleyball;
      case 'sports_badminton':
        return Icons.sports_tennis; // No specific badminton icon
      case 'sports_pickleball':
        return Icons.sports_tennis; // Similar to tennis
      case 'sports_padel':
        return Icons.sports_tennis; // Similar to tennis
      case 'sports_futsal':
        return Icons.sports_soccer; // Indoor soccer
      case 'sports_table_tennis':
        return Icons.sports_tennis;
      case 'sports_squash':
        return Icons.sports_tennis;
      case 'sports_handball':
        return Icons.sports_handball;
      case 'sports_racquetball':
        return Icons.sports_tennis;
      default:
        return Icons.sports;
    }
  }

  /// Get a color associated with the sport
  Color get color {
    switch (name.toLowerCase()) {
      case 'tennis':
        return const Color(0xFF4CAF50); // Green
      case 'basketball':
        return const Color(0xFFFF9800); // Orange
      case 'soccer':
        return const Color(0xFF2196F3); // Blue
      case 'volleyball':
        return const Color(0xFFE91E63); // Pink
      case 'badminton':
        return const Color(0xFF9C27B0); // Purple
      case 'pickleball':
        return const Color(0xFF00BCD4); // Cyan
      case 'padel':
        return const Color(0xFF3F51B5); // Indigo
      case 'futsal':
        return const Color(0xFF009688); // Teal
      case 'table tennis':
        return const Color(0xFFF44336); // Red
      case 'squash':
        return const Color(0xFF795548); // Brown
      case 'handball':
        return const Color(0xFFFF5722); // Deep Orange
      case 'racquetball':
        return const Color(0xFF607D8B); // Blue Grey
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  @override
  String toString() {
    return 'SportModel(id: $id, name: $name, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SportModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
