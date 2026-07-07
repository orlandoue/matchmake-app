import 'package:orland_sports/const/supabase_tables.dart';
import 'package:orland_sports/models/court_model.dart';
import 'package:orland_sports/models/sport_model.dart';
import 'package:orland_sports/services/supabase_crud.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for sport-related operations
class SportService {
  // Private constructor
  SportService._privateConstructor();

  // Singleton instance variable
  static SportService? _instance;

  // Getter to access the singleton instance
  static SportService get instance {
    _instance ??= SportService._privateConstructor();
    return _instance!;
  }

  final _crudService = SupabaseDatabaseService.instance;
  final _supabase = Supabase.instance.client;

  // ==================== SPORT OPERATIONS ====================

  /// Get all sports
  Future<List<SportModel>> getAllSports() async {
    try {
      final response = await _crudService.readAllRows(
        tableName: SupabaseTables.sportsTable,
      );

      if (response != null) {
        return response.map((json) => SportModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting all sports: $e');
      return [];
    }
  }

  /// Get all active sports
  Future<List<SportModel>> getActiveSports() async {
    try {
      final response = await _crudService.readRowsByField(
        tableName: SupabaseTables.sportsTable,
        fieldName: 'is_active',
        fieldValue: true,
      );

      if (response != null) {
        return response.map((json) => SportModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting active sports: $e');
      return [];
    }
  }

  /// Get sport by ID
  Future<SportModel?> getSportById(String sportId) async {
    try {
      final response = await _crudService.readSingleRow(
        tableName: SupabaseTables.sportsTable,
        rowId: sportId,
      );

      if (response != null) {
        return SportModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error getting sport by ID: $e');
      return null;
    }
  }

  /// Get sport by name
  Future<SportModel?> getSportByName(String name) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.sportsTable)
          .select()
          .ilike('name', name)
          .maybeSingle();

      if (response != null) {
        return SportModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error getting sport by name: $e');
      return null;
    }
  }

  /// Create a new sport (Admin only)
  Future<bool> createSport(SportModel sport) async {
    try {
      return await _crudService.createRow(
        tableName: SupabaseTables.sportsTable,
        rowId: sport.id,
        data: sport.toJson(),
      );
    } catch (e) {
      print('Error creating sport: $e');
      return false;
    }
  }

  /// Update sport details (Admin only)
  Future<bool> updateSport(SportModel sport) async {
    try {
      return await _crudService.updateRow(
        tableName: SupabaseTables.sportsTable,
        rowId: sport.id,
        data: sport.toJson(),
      );
    } catch (e) {
      print('Error updating sport: $e');
      return false;
    }
  }

  /// Delete sport (Admin only)
  Future<bool> deleteSport(String sportId) async {
    try {
      return await _crudService.deleteRow(
        tableName: SupabaseTables.sportsTable,
        rowId: sportId,
      );
    } catch (e) {
      print('Error deleting sport: $e');
      return false;
    }
  }

  // ==================== COURT-SPORT RELATIONSHIP OPERATIONS ====================

  /// Get all sports for a specific court
  Future<List<SportModel>> getSportsForCourt(String courtId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.courtsTable)
          .select('sports(*)')
          .eq('id', courtId)
          .maybeSingle();

      if (response == null || response['sports'] == null) return [];

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

  /// Get all courts that have a specific sport
  Future<List<CourtModel>> getCourtsForSport(String sportId) async {
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
      print('Error getting courts for sport: $e');
      return [];
    }
  }

  /// Assign a sport to a court (Admin only)
  Future<bool> assignSportToCourt({
    required String courtId,
    required String sportId,
  }) async {
    try {
      await _supabase.from(SupabaseTables.courtsTable).update({
        'sport_id': sportId,
      }).eq('id', courtId);
      return true;
    } catch (e) {
      print('Error assigning sport to court: $e');
      return false;
    }
  }

  /// Remove a sport from a court (Admin only)
  Future<bool> removeSportFromCourt({
    required String courtId,
    required String sportId,
  }) async {
    try {
      await _supabase.from(SupabaseTables.courtsTable).update({
        'sport_id': null,
      }).eq('id', courtId);
      return true;
    } catch (e) {
      print('Error removing sport from court: $e');
      return false;
    }
  }

  /// Update all sports for a court (replaces existing sports)
  Future<bool> updateCourtSports({
    required String courtId,
    required List<String> sportIds,
  }) async {
    try {
      // Direct relationship: we only take the first sport if multiple are provided
      final sportId = sportIds.isNotEmpty ? sportIds.first : null;
      await _supabase.from(SupabaseTables.courtsTable).update({
        'sport_id': sportId,
      }).eq('id', courtId);

      return true;
    } catch (e) {
      print('Error updating court sports: $e');
      return false;
    }
  }

  /// Check if a sport is assigned to a court
  Future<bool> isSportAssignedToCourt({
    required String courtId,
    required String sportId,
  }) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.courtsTable)
          .select('id')
          .eq('id', courtId)
          .eq('sport_id', sportId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking sport assignment: $e');
      return false;
    }
  }

  /// Get count of courts for each sport
  Future<Map<String, int>> getCourtCountBySport() async {
    try {
      final response = await _supabase
          .from(SupabaseTables.courtsTable)
          .select('sport_id')
          .not('sport_id', 'is', null);

      final countMap = <String, int>{};
      for (final item in response as List) {
        final sportId = item['sport_id'] as String;
        countMap[sportId] = (countMap[sportId] ?? 0) + 1;
      }

      return countMap;
    } catch (e) {
      print('Error getting court count by sport: $e');
      return {};
    }
  }

  /// Stream sports for real-time updates
  Stream<List<SportModel>> streamActiveSports() {
    return _supabase
        .from(SupabaseTables.sportsTable)
        .stream(primaryKey: ['id']).map((data) => data
            .where((item) => item['is_active'] == true)
            .map((json) => SportModel.fromJson(json))
            .toList());
  }
}
