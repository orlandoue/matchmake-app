import 'package:orland_sports/const/supabase_tables.dart';
import 'package:orland_sports/models/club_model.dart';
import 'package:orland_sports/models/court_model.dart';
import 'package:orland_sports/models/sport_model.dart';
import 'package:orland_sports/services/supabase_crud.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for court-related operations
class CourtService {
  // Private constructor
  CourtService._privateConstructor();

  // Singleton instance variable
  static CourtService? _instance;

  // Getter to access the singleton instance
  static CourtService get instance {
    _instance ??= CourtService._privateConstructor();
    return _instance!;
  }

  final _crudService = SupabaseDatabaseService.instance;
  final _supabase = Supabase.instance.client;

  // ==================== CLUB OPERATIONS (GEO) ====================

  /// Get clubs within a radius using the PostGIS RPC `get_clubs_in_range`.
  /// [lat]/[lng] are decimal degrees, [radiusKm] is converted to meters.
  /// [sportId] is optional — if provided, only clubs with courts for that sport are returned.
  Future<List<ClubModel>> getClubsInRange({
    required double lat,
    required double lng,
    required double radiusKm,
    String? sportId,
  }) async {
    try {
      // PostGIS ST_GeogFromText expects POINT(longitude latitude)
      final userLocation = 'POINT($lng $lat)';
      final rangeMeters = radiusKm * 1000.0;

      final params = <String, dynamic>{
        'user_location': userLocation,
        'range_meters': rangeMeters,
      };
      // Only include p_sport_id if provided — DB default is NULL
      if (sportId != null) {
        params['p_sport_id'] = sportId;
      }

      print('🔍 RPC get_clubs_in_range → location: $userLocation, range: ${rangeMeters}m, sport: $sportId');

      print('🔥 ALERTA RPC -> WKT: $userLocation | Metros: $rangeMeters | DeporteID: $sportId');

      final response = await _supabase.rpc(
        'get_clubs_in_range',
        params: params,
      );

      if (response == null || (response as List).isEmpty) {
        print('⚠️ get_clubs_in_range returned 0 results.');
        return [];
      }
      print('✅ get_clubs_in_range returned ${(response).length} clubs.');
      return (response)
          .map((json) => ClubModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error calling get_clubs_in_range RPC: $e');
      return [];
    }
  }

  // ==================== COURT OPERATIONS ====================

  /// Get all courts with their sports
  Future<List<CourtModel>> getAllCourts() async {
    try {
      final response = await _supabase
          .from(SupabaseTables.courtsTable)
          .select('*, sports(*)');

      if (response.isNotEmpty) {
        return (response as List)
            .map((json) => CourtModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting all courts: $e');
      return [];
    }
  }

  /// Get all active courts with their sports
  Future<List<CourtModel>> getActiveCourts() async {
    try {
      final response = await _supabase
          .from(SupabaseTables.courtsTable)
          .select('*, sports(*)')
          .eq('is_active', true);

      if (response.isNotEmpty) {
        return (response as List)
            .map((json) => CourtModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting active courts: $e');
      return [];
    }
  }

  /// Get court by ID with sports
  Future<CourtModel?> getCourtById(String courtId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.courtsTable)
          .select('*, sports(*)')
          .eq('id', courtId)
          .maybeSingle();

      if (response != null) {
        return CourtModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error getting court by ID: $e');
      return null;
    }
  }

  /// Get courts by sport ID
  Future<List<CourtModel>> getCourtsBySport(String sportId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.courtsTable)
          .select('*, sports(*)')
          .eq('sport_id', sportId);

      if (response.isEmpty) return [];

      return (response as List)
          .map((json) => CourtModel.fromJson(json as Map<String, dynamic>))
          .where((court) => court.isActive)
          .toList();
    } catch (e) {
      print('Error getting courts by sport: $e');
      return [];
    }
  }

  /// Get courts by multiple sport IDs (courts that have ANY of the specified sports)
  Future<List<CourtModel>> getCourtsBySports(List<String> sportIds) async {
    try {
      if (sportIds.isEmpty) return getActiveCourts();

      final response = await _supabase
          .from(SupabaseTables.courtsTable)
          .select('*, sports(*)')
          .inFilter('sport_id', sportIds);

      if (response.isEmpty) return [];

      return (response as List)
          .map((json) => CourtModel.fromJson(json as Map<String, dynamic>))
          .where((court) => court.isActive)
          .toList();
    } catch (e) {
      print('Error getting courts by sports: $e');
      return [];
    }
  }

  /// Get sports for a specific court
  Future<List<SportModel>> getSportsForCourt(String courtId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.courtsTable)
          .select('sports(*)')
          .eq('id', courtId)
          .maybeSingle();

      if (response == null || response['sports'] == null) return [];

      // Handle the Many-to-One case (Map) vs One-to-Many case (List)
      final sportsData = response['sports'];
      if (sportsData is List) {
        return sportsData
            .map((json) => SportModel.fromJson(json as Map<String, dynamic>))
            .where((sport) => sport.isActive)
            .toList();
      } else if (sportsData is Map) {
        final sport =
            SportModel.fromJson(sportsData as Map<String, dynamic>);
        return sport.isActive ? [sport] : [];
      }
      return [];
    } catch (e) {
      print('Error getting sports for court: $e');
      return [];
    }
  }

  /// Create a new court (Admin only)
  Future<bool> createCourt(CourtModel court) async {
    try {
      return await _crudService.createRow(
        tableName: SupabaseTables.courtsTable,
        rowId: court.id,
        data: court.toJson(),
      );
    } catch (e) {
      print('Error creating court: $e');
      return false;
    }
  }

  /// Update court details (Admin only)
  Future<bool> updateCourt(CourtModel court) async {
    try {
      return await _crudService.updateRow(
        tableName: SupabaseTables.courtsTable,
        rowId: court.id,
        data: court.toJson(),
      );
    } catch (e) {
      print('Error updating court: $e');
      return false;
    }
  }

  /// Delete court (Admin only)
  Future<bool> deleteCourt(String courtId) async {
    try {
      return await _crudService.deleteRow(
        tableName: SupabaseTables.courtsTable,
        rowId: courtId,
      );
    } catch (e) {
      print('Error deleting court: $e');
      return false;
    }
  }

  // ==================== REFREEE GIG ECONOMY ====================
  // Table 'court_assignments' is deprecated. 
  // Referees now claim matches directly via MatchService.claimMatch().
}
