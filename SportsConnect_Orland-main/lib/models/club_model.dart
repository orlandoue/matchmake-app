import 'dart:math' as math;

/// Model representing a Club (Recinto) in the database.
/// A Club is the parent entity of Courts (Canchas).
class ClubModel {
  final String id;
  final String name;
  final String? address;
  final double lat;
  final double lng;
  final String? imageUrl;
  final String? phone;
  final String? email;
  final bool isActive;
  final DateTime? createdAt;

  // SII Info
  final String? razonSocial;
  final String? rutEmpresa;
  final String? giro;

  // Banking Info
  final String? banco;
  final String? tipoCuenta;
  final String? numeroCuenta;
  final String? emailPagos;

  /// Distance from the user's position in km (populated from RPC)
  final double? distanceKm;

  ClubModel({
    required this.id,
    required this.name,
    this.address,
    required this.lat,
    required this.lng,
    this.imageUrl,
    this.phone,
    this.email,
    this.isActive = true,
    this.createdAt,
    this.distanceKm,
    this.razonSocial,
    this.rutEmpresa,
    this.giro,
    this.banco,
    this.tipoCuenta,
    this.numeroCuenta,
    this.emailPagos,
  });

  /// Create ClubModel from JSON map (from Supabase RPC or table query)
  factory ClubModel.fromJson(Map<String, dynamic> json) {
    // Helper: safely parse any numeric value as double
    double _d(dynamic v, [double fallback = 0.0]) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    return ClubModel(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Club sin nombre',
      address: json['address'] as String?,
      lat: _d(json['latitude'] ?? json['lat']),
      lng: _d(json['longitude'] ?? json['lng']),
      imageUrl: json['image_url'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      // RPC returns distance_m (meters) — convert to km for display
      distanceKm: json['distance_m'] != null
          ? _d(json['distance_m']) / 1000.0
          : (json['distance_km'] != null ? _d(json['distance_km']) : null),
      razonSocial: json['razon_social'] as String?,
      rutEmpresa: json['rut_empresa'] as String?,
      giro: json['giro'] as String?,
      banco: json['banco'] as String?,
      tipoCuenta: json['tipo_cuenta'] as String?,
      numeroCuenta: json['numero_cuenta'] as String?,
      emailPagos: json['email_pagos'] as String?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': lat,
      'longitude': lng,
      'image_url': imageUrl,
      'phone': phone,
      'email': email,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'razon_social': razonSocial,
      'rut_empresa': rutEmpresa,
      'giro': giro,
      'banco': banco,
      'tipo_cuenta': tipoCuenta,
      'numero_cuenta': numeroCuenta,
      'email_pagos': emailPagos,
    };
  }

  /// Calculate distance in km from a given coordinate using the Haversine formula.
  double distanceTo(double userLat, double userLng) {
    const double earthRadius = 6371.0;
    final dLat = _toRad(lat - userLat);
    final dLng = _toRad(lng - userLng);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(userLat)) *
            math.cos(_toRad(lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRad(double deg) => deg * math.pi / 180;

  /// Returns a formatted distance string (uses distanceKm if provided, otherwise calculates)
  String distanceLabel(double userLat, double userLng) {
    final d = distanceKm ?? distanceTo(userLat, userLng);
    if (d < 1.0) return '${(d * 1000).toStringAsFixed(0)} m';
    return '${d.toStringAsFixed(1)} km';
  }

  /// Create a copy with updated fields
  ClubModel copyWith({
    String? id,
    String? name,
    String? address,
    double? lat,
    double? lng,
    String? imageUrl,
    String? phone,
    String? email,
    bool? isActive,
    DateTime? createdAt,
    double? distanceKm,
  }) {
    return ClubModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      imageUrl: imageUrl ?? this.imageUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      distanceKm: distanceKm ?? this.distanceKm,
      razonSocial: razonSocial ?? this.razonSocial,
      rutEmpresa: rutEmpresa ?? this.rutEmpresa,
      giro: giro ?? this.giro,
      banco: banco ?? this.banco,
      tipoCuenta: tipoCuenta ?? this.tipoCuenta,
      numeroCuenta: numeroCuenta ?? this.numeroCuenta,
      emailPagos: emailPagos ?? this.emailPagos,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClubModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ClubModel(id: $id, name: $name, distanceKm: $distanceKm)';
}
