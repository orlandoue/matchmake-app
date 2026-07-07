import 'package:orland_sports/models/sport_model.dart';

/// Court model representing an individual court (cancha) within a club.
/// This is the legacy model used throughout court management, referee,
/// explore flows, and match creation.
class CourtModel {
  final String id;
  final String? clubId;
  final String name;
  final String? description;
  final String? address;
  final String? imageUrl;
  final bool isActive;
  final bool isIndoor;
  final String? surfaceType;

  /// Non-nullable lat/lng — defaults to 0.0 if absent in the DB row,
  /// so ExploreController and MapsController can do math without null checks.
  final double latitude;
  final double longitude;

  final String? phone;
  final String? email;

  // ── Extra fields expected by legacy screens ──────────────────────────────
  final String? openingTime;
  final String? closingTime;
  final double? hourlyRate;
  final List<String>? amenities;
  final String? contactPhone;
  final String? contactEmail;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ── Joined relations ─────────────────────────────────────────────────────
  final List<SportModel>? sports;

  CourtModel({
    required this.id,
    this.clubId,
    required this.name,
    this.description,
    this.address,
    this.imageUrl,
    this.isActive = true,
    this.isIndoor = false,
    this.surfaceType,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.phone,
    this.email,
    this.openingTime,
    this.closingTime,
    this.hourlyRate,
    this.amenities,
    this.contactPhone,
    this.contactEmail,
    this.createdAt,
    this.updatedAt,
    this.sports,
  });

  /// Create CourtModel from JSON map
  factory CourtModel.fromJson(Map<String, dynamic> json) {
    // Parse nested sports direct relationship
    List<SportModel>? sportsList;
    if (json['sports'] != null) {
      if (json['sports'] is List) {
        sportsList = (json['sports'] as List)
            .map((s) => SportModel.fromJson(s as Map<String, dynamic>))
            .toList();
      } else if (json['sports'] is Map) {
        sportsList = [
          SportModel.fromJson(json['sports'] as Map<String, dynamic>)
        ];
      }
    }

    // Parse amenities (stored as JSON array)
    List<String>? amenitiesList;
    if (json['amenities'] != null) {
      amenitiesList = List<String>.from(json['amenities'] as List);
    }

    return CourtModel(
      id: json['id'] as String,
      clubId: json['club_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      address: json['address'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isIndoor: json['is_indoor'] as bool? ?? false,
      surfaceType: json['surface_type'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : 0.0,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : 0.0,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      openingTime: json['opening_time'] as String?,
      closingTime: json['closing_time'] as String?,
      hourlyRate: json['hourly_rate'] != null
          ? (json['hourly_rate'] as num).toDouble()
          : null,
      amenities: amenitiesList,
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      sports: sportsList,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'club_id': clubId,
      'name': name,
      'description': description,
      'address': address,
      'image_url': imageUrl,
      'is_active': isActive,
      'is_indoor': isIndoor,
      'surface_type': surfaceType,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'hourly_rate': hourlyRate,
      'amenities': amenities,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  CourtModel copyWith({
    String? id,
    String? clubId,
    String? name,
    String? description,
    String? address,
    String? imageUrl,
    bool? isActive,
    bool? isIndoor,
    String? surfaceType,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    String? openingTime,
    String? closingTime,
    double? hourlyRate,
    List<String>? amenities,
    String? contactPhone,
    String? contactEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SportModel>? sports,
  }) {
    return CourtModel(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      isIndoor: isIndoor ?? this.isIndoor,
      surfaceType: surfaceType ?? this.surfaceType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      amenities: amenities ?? this.amenities,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sports: sports ?? this.sports,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourtModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CourtModel(id: $id, name: $name, isActive: $isActive)';
}
