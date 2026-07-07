import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:orland_sports/models/club_model.dart';
import 'package:orland_sports/models/court_model.dart';
import 'package:orland_sports/models/sport_model.dart';
import 'package:orland_sports/models/match_model.dart';
import 'package:orland_sports/enums/match_status.dart';

class ClubAdminService {
  static ClubAdminService? _instance;
  static ClubAdminService get instance {
    _instance ??= ClubAdminService._();
    return _instance!;
  }

  ClubAdminService._();

  final _supabase = Supabase.instance.client;

  /// Fetch the club that belongs to the current logged-in user
  Future<ClubModel?> getClubByOwnerId(String ownerId) async {
    try {
      final response = await _supabase
          .from('clubs')
          .select()
          .eq('owner_id', ownerId)
          .maybeSingle();

      if (response != null) {
        return ClubModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching club by owner: $e');
      return null;
    }
  }

  /// Fetch all courts belonging to a specific club
  Future<List<CourtModel>> getCourtsByClubId(String clubId) async {
    try {
      final response = await _supabase
          .from('courts')
          .select('*, sports(*)')
          .eq('club_id', clubId)
          .order('created_at', ascending: false);

      if (response.isNotEmpty) {
        return (response as List)
            .map((json) => CourtModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching courts by club_id: $e');
      return [];
    }
  }

  /// Get total matches played in courts belonging to this club
  Future<int> getPlayedMatchesCount(String clubId) async {
    try {
      // 1. Get all court ids for this club
      final courts = await _supabase
          .from('courts')
          .select('id')
          .eq('club_id', clubId);

      if (courts.isEmpty) return 0;
      
      final courtIds = (courts as List).map((e) => e['id']).toList();

      // 2. Count matches that happened in those courts and are 'completed'
      final matchesCountResponse = await _supabase
          .from('matches')
          .select('id')
          .inFilter('court_id', courtIds)
          .eq('status', 'completed');

      return (matchesCountResponse as List).length;
    } catch (e) {
      print('Error fetching completed matches count: $e');
      return 0;
    }
  }

  /// Returns real KPI counts for the B2B dashboard: today / week / month.
  /// Counts matched/confirmed/in_progress/completed matches (real reservations only).
  Future<Map<String, int>> getScheduledMatchesKpis(String clubId) async {
    try {
      final courtRows = await _supabase
          .from('courts')
          .select('id')
          .eq('club_id', clubId);

      if ((courtRows as List).isEmpty) {
        return {'today': 0, 'week': 0, 'month': 0};
      }
      final courtIds = courtRows.map((e) => e['id'] as String).toList();

      const counted = ['matched', 'confirmed', 'in_progress', 'completed'];
      final now = DateTime.now();
      String pad(int n) => n.toString().padLeft(2, '0');

      final weekStart     = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd       = weekStart.add(const Duration(days: 6));
      final monthStartStr = '${now.year}-${pad(now.month)}-01';
      final lastDay       = DateTime(now.year, now.month + 1, 0).day;
      final monthEndStr   = '${now.year}-${pad(now.month)}-$lastDay';

      final rows = await _supabase
          .from('matches')
          .select('scheduled_date')
          .inFilter('court_id', courtIds)
          .inFilter('status', counted)
          .gte('scheduled_date', monthStartStr)
          .lte('scheduled_date', monthEndStr);

      int today = 0, week = 0, month = 0;
      final todayDate     = DateTime(now.year, now.month, now.day);
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final weekEndDate   = DateTime(weekEnd.year, weekEnd.month, weekEnd.day);

      for (final row in (rows as List)) {
        final dStr = row['scheduled_date'] as String? ?? '';
        if (dStr.isEmpty) continue;
        final parsed = DateTime.tryParse(dStr);
        if (parsed == null) continue;
        final dDate = DateTime(parsed.year, parsed.month, parsed.day);

        month++;
        if (!dDate.isBefore(weekStartDate) && !dDate.isAfter(weekEndDate)) week++;
        if (dDate == todayDate) today++;
      }

      return {'today': today, 'week': week, 'month': month};
    } catch (e) {
      print('Error fetching dashboard KPIs: $e');
      return {'today': 0, 'week': 0, 'month': 0};
    }
  }

  /// Fetch all available sports for the dropdown
  Future<List<SportModel>> getAllSports() async {
    try {
      final response = await _supabase
          .from('sports')
          .select()
          .eq('is_active', true)
          .order('name');
          
      if (response.isNotEmpty) {
        return (response as List)
            .map((json) => SportModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching sports: $e');
      return [];
    }
  }

  /// Add a new court
  Future<bool> createCourt(String name, String clubId, String sportId) async {
    try {
      await _supabase.from('courts').insert({
        'name': name,
        'club_id': clubId,
        'sport_id': sportId,
        'is_active': true,
        // Provide coordinates of the club if necessary, or let DB default
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error creating new court: $e');
      return false;
    }
  }

  /// Get scheduled matches for a given date across the club's courts.
  /// Returns matches that are matched, confirmed, in_progress, completed or blocked.
  /// Matches still in 'waiting_for_opponent' (searching phase)
  /// are excluded so they don't block courts prematurely.
  Future<List<MatchModel>> getMatchesForDate(
      List<String> courtIds, DateTime date) async {
    if (courtIds.isEmpty) return [];
    try {
      final dateString = date.toIso8601String().split('T').first;

      // Whitelist: statuses that mean the match is full or confirmed & should appear
      // on the club agenda grid.
      const agendaStatuses = [
        'matched',
        'confirmed',
        'in_progress',
        'completed',
        'blocked',      // manual court blocks by club admin
      ];

      final response = await _supabase
          .from('matches')
          .select()
          .inFilter('court_id', courtIds)
          .eq('scheduled_date', dateString)
          .inFilter('status', agendaStatuses);

      if (response.isNotEmpty) {
        return (response as List)
            .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching matches for agenda: $e');
      return [];
    }
  }

  /// Manually block a court at a specific date and time
  Future<bool> createManualReservation(
      String courtId, DateTime date, String time) async {
    try {
      final dateString = date.toIso8601String().split('T').first;
      
      final currentUser = _supabase.auth.currentUser;
      await _supabase.from('matches').insert({
        'court_id': courtId,
        'scheduled_date': dateString,
        'scheduled_time': time,
        'status': MatchStatus.blocked.value,
        'match_mode': MatchMode.manualReservation.value,
        'player1_id': currentUser?.id, // Required by DB NOT NULL constraint & RLS policy
      });
      return true;
    } catch (e) {
      print('Error creating manual reservation: $e');
      return false;
    }
  }

  /// Delete a match (unblock court)
  Future<bool> deleteMatch(String matchId) async {
    try {
      await _supabase.from('matches').delete().eq('id', matchId);
      return true;
    } catch (e) {
      print('Error deleting match: $e');
      return false;
    }
  }

  /// Create a new Club (Onboarding)
  Future<ClubModel?> createClub(String name, String phone, String address, double lat, double lng, String ownerId) async {
    try {
      final response = await _supabase.from('clubs').insert({
        'name': name,
        'contact_phone': phone,
        'address': address,
        'latitude': lat,
        'longitude': lng,
        'owner_id': ownerId,
      }).select().single();
      
      return ClubModel.fromJson(response);
    } catch (e) {
      print('Error creating club: $e');
      return null;
    }
  }

  /// Fetch all completed, billable matches for the ClubWalletController.
  /// Joins courts to pull hourly_rate (the club's revenue per match).
  /// Excludes manual_reservation matches — clubs only earn from platform matches.
  Future<List<Map<String, dynamic>>> getCompletedMatchesForWallet(String clubId) async {
    try {
      final courtRows = await _supabase
          .from('courts')
          .select('id')
          .eq('club_id', clubId);

      if ((courtRows as List).isEmpty) return [];

      final courtIds = courtRows.map((e) => e['id'] as String).toList();

      final rows = await _supabase
          .from('matches')
          .select('id, scheduled_date, sport_id, match_mode, courts(id, hourly_rate, name), sports(name)')
          .inFilter('court_id', courtIds)
          .eq('status', 'completed')
          .neq('match_mode', 'manual_reservation')
          .order('scheduled_date', ascending: false);

      return (rows as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching wallet matches: $e');
      return [];
    }
  }

  /// Update Club Profile
  Future<bool> updateClubProfile(String clubId, Map<String, dynamic> data) async {
    try {
      await _supabase.from('clubs').update(data).eq('id', clubId);
      return true;
    } catch (e) {
      print('Error updating club profile: $e');
      return false;
    }
  }
}
