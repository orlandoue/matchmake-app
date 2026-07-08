import 'package:intl/intl.dart';
import 'package:orland_sports/const/supabase_tables.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/match_model.dart';
import 'package:orland_sports/services/match_queries.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Search & scheduling algorithms for matchmaking.
///
/// Owns the "find someone/somewhere to play" logic: locating joinable matches
/// (by court, by clubs, for duos), conflict detection, best-slot resolution
/// and free-court assignment. Pure reads/RPC — it never mutates a match; the
/// actual join/update lives in [MatchService].
class MatchmakingService {
  MatchmakingService._privateConstructor();

  static MatchmakingService? _instance;

  static MatchmakingService get instance {
    _instance ??= MatchmakingService._privateConstructor();
    return _instance!;
  }

  final _supabase = Supabase.instance.client;

  /// Check if a conflicting match exists at the same court/date/time.
  /// Returns true if a conflict exists, false otherwise.
  Future<bool> hasConflictingMatch({
    required String courtId,
    required DateTime scheduledDate,
    required String scheduledTime,
    String? excludeMatchId,
  }) async {
    try {
      var query = _supabase
          .from(SupabaseTables.matchesTable)
          .select('id')
          .eq('court_id', courtId)
          .eq('scheduled_date', scheduledDate.toIso8601String().split('T')[0])
          .eq('scheduled_time', scheduledTime)
          .inFilter('status', [
            MatchStatus.matched.value,
            MatchStatus.confirmed.value,
            MatchStatus.inProgress.value,
            MatchStatus.completed.value,
          ]);

      if (excludeMatchId != null) {
        query = query.neq('id', excludeMatchId);
      }

      final response = await query;
      return (response as List).isNotEmpty;
    } catch (e) {
      print('Error checking for conflicting match: $e');
      return false;
    }
  }

  /// Find available match for random matchmaking (legacy: by specific court)
  Future<MatchModel?> findAvailableMatch({
    required String courtId,
    required DateTime scheduledDate,
    required String scheduledTime,
    String? scheduledEndTime, // ADDED for time window check
    required MatchType matchType,
    required String currentPlayerId,
    String? sportId, // ← filters by sport UUID; prevents cross-sport joins
  }) async {
    try {
      var query = _supabase
          .from(SupabaseTables.matchesTable)
          .select(kMatchSelectQuery)
          .eq('court_id', courtId)
          .eq('scheduled_date', scheduledDate.toIso8601String().split('T')[0])
          .eq('match_type', matchType.value)
          .eq('match_mode', MatchMode.competitive.value)
          .eq('status', MatchStatus.waitingForOpponent.value)
          .neq('player1_id', currentPlayerId);

      // CRITICAL: only join matches of the same sport
      if (sportId != null) {
        query = query.eq('sport_id', sportId);
      }

      final response = await query.limit(50);
      final matches =
          (response as List).map((json) => MatchModel.fromJson(json)).toList();

      for (final match in matches) {
        if (match.matchType == MatchType.twoVsTwo &&
            match.invitedPlayer2Id != null &&
            match.player2Id == null) {
          continue;
        }

        if (_isMatchWithinSearchWindow(match, scheduledTime, scheduledEndTime)) {
          return match;
        }
      }
      return null;
    } catch (e) {
      print('Error finding available match: $e');
      return null;
    }
  }

  /// Find best match slot using RPC for Flex-Match
  Future<String?> findBestMatchSlot({
    required String clubId,
    required String startWindowIso,
    required String endWindowIso,
    required int durationMinutes,
  }) async {
    try {
      final response = await _supabase.rpc('find_best_match_slot', params: {
        'p_club_id': clubId,
        'p_start_window': startWindowIso,
        'p_end_window': endWindowIso,
        'p_duration_minutes': durationMinutes,
      });
      return response?.toString();
    } catch (e) {
      print('Error finding best match slot: $e');
      return null;
    }
  }

  /// Find available match in GEO flow: looks for waiting matches whose
  /// preferred_club_ids overlap with the given clubIds list.
  Future<MatchModel?> findAvailableMatchByClubs({
    required List<String> clubIds,
    required DateTime scheduledDate,
    required String scheduledTime,
    String? scheduledEndTime, // ADDED for time window check
    required MatchType matchType,
    required String currentPlayerId,
    String? sportId, // ← CRITICAL: filters by sport UUID; prevents cross-sport joins
  }) async {
    try {
      if (clubIds.isEmpty) return null;

      var query = _supabase
          .from(SupabaseTables.matchesTable)
          .select(kMatchSelectQuery)
          // Removed: .isFilter('court_id', null) to allow finding matches with a specific court
          .eq('scheduled_date', scheduledDate.toIso8601String().split('T')[0])
          .eq('match_type', matchType.value)
          .eq('match_mode', MatchMode.competitive.value)
          .eq('status', MatchStatus.waitingForOpponent.value)
          .neq('player1_id', currentPlayerId);

      // CRITICAL: only join matches of the same sport
      if (sportId != null) {
        query = query.eq('sport_id', sportId);
      }

      final response = await query.limit(50);
      final matches =
          (response as List).map((json) => MatchModel.fromJson(json)).toList();

      for (final match in matches) {
        if (match.matchType == MatchType.twoVsTwo &&
            match.invitedPlayer2Id != null &&
            match.player2Id == null) {
          continue;
        }

        if (!_isMatchWithinSearchWindow(match, scheduledTime, scheduledEndTime)) {
          continue;
        }

        // Check mapping: If it has a court, check court's clubId. Otherwise check preferredClubIds.
        bool hasOverlap = false;
        if (match.courtId != null && match.court != null) {
          hasOverlap = clubIds.contains(match.court!.clubId);
        } else {
          hasOverlap = match.preferredClubIds.any((id) => clubIds.contains(id));
        }

        if (hasOverlap) return match;
      }
      return null;
    } catch (e) {
      print('Error finding available match by clubs: $e');
      return null;
    }
  }

  /// Finds a 2v2 match that has at least 2 free player slots (for duo search).
  Future<MatchModel?> findAvailableMatchForDuo({
    required List<String> clubIds,
    required DateTime scheduledDate,
    required String scheduledTime,
    String? scheduledEndTime,
    required String currentPlayerId,
    required String partnerId,
  }) async {
    try {
      if (clubIds.isEmpty) return null;

      // Fetch 2v2 candidates waiting for opponents
      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .select(kMatchSelectQuery)
          .isFilter('court_id', null)
          .eq('scheduled_date', scheduledDate.toIso8601String().split('T')[0])
          .eq('match_type', MatchType.twoVsTwo.value)
          .eq('match_mode', MatchMode.competitive.value)
          .eq('status', MatchStatus.waitingForOpponent.value)
          .neq('player1_id', currentPlayerId)
          .neq('player1_id', partnerId)
          .limit(50);

      final matches =
          (response as List).map((json) => MatchModel.fromJson(json)).toList();

      for (final match in matches) {
        // Count free slots
        final freeSlots = [
          match.player2Id,
          match.player3Id,
          match.player4Id,
        ].where((id) => id == null).length;

        if (freeSlots < 2) continue; // Not enough space for the duo

        if (!_isMatchWithinSearchWindow(match, scheduledTime, scheduledEndTime)) {
          continue;
        }

        // Check club overlap
        final hasOverlap =
            match.preferredClubIds.any((id) => clubIds.contains(id));
        if (hasOverlap) return match;
      }
      return null;
    } catch (e) {
      print('Error finding match for duo: $e');
      return null;
    }
  }

  /// Checks if an existing match's time fully falls inside the search window,
  /// or overlaps by at least 60 minutes for legacy flexibility.
  bool isMatchWithinSearchWindow(
          MatchModel match, String? searchStartStr, String? searchEndTimeStr) =>
      _isMatchWithinSearchWindow(match, searchStartStr, searchEndTimeStr);

  bool _isMatchWithinSearchWindow(
      MatchModel match, String? searchStartStr, String? searchEndTimeStr) {
    if (searchStartStr == null || searchStartStr.isEmpty) return true;
    if (searchEndTimeStr == null || searchEndTimeStr.isEmpty) {
      return match.scheduledTime == searchStartStr;
    }

    try {
      final format = DateFormat("h:mm a");
      final searchStart = format.parse(searchStartStr);
      final searchEnd = format.parse(searchEndTimeStr);

      final matchStart = format.parse(match.scheduledTime);
      DateTime matchEnd;
      if (match.scheduledEndTime != null && match.scheduledEndTime!.isNotEmpty) {
        matchEnd = format.parse(match.scheduledEndTime!);
      } else {
        matchEnd = matchStart.add(const Duration(minutes: 60)); // fallback
      }

      final baseDate = DateTime(2000, 1, 1);
      DateTime sStart = DateTime(baseDate.year, baseDate.month, baseDate.day,
          searchStart.hour, searchStart.minute);
      DateTime sEnd = DateTime(baseDate.year, baseDate.month, baseDate.day,
          searchEnd.hour, searchEnd.minute);
      if (sEnd.isBefore(sStart)) sEnd = sEnd.add(const Duration(days: 1));

      DateTime mStart = DateTime(baseDate.year, baseDate.month, baseDate.day,
          matchStart.hour, matchStart.minute);
      DateTime mEnd = DateTime(baseDate.year, baseDate.month, baseDate.day,
          matchEnd.hour, matchEnd.minute);
      if (mEnd.isBefore(mStart)) mEnd = mEnd.add(const Duration(days: 1));

      // 1. Fully contained
      bool isContained =
          (mStart.isAtSameMomentAs(sStart) || mStart.isAfter(sStart)) &&
              (mEnd.isAtSameMomentAs(sEnd) || mEnd.isBefore(sEnd));

      if (isContained) return true;

      // 2. Fallback: Check if they overlap by at least 60 minutes to be generous
      final overlapStart = mStart.isAfter(sStart) ? mStart : sStart;
      final overlapEnd = mEnd.isBefore(sEnd) ? mEnd : sEnd;
      final overlapMinutes = overlapEnd.difference(overlapStart).inMinutes;

      return overlapMinutes >= 60;
    } catch (e) {
      print('Error parsing times for overlap check: $e');
      return match.scheduledTime == searchStartStr;
    }
  }

  /// Asigna la mejor cancha disponible en el momento que un partido geo-rutado
  /// hace match y define un horario fijo.
  Future<String?> findFreeCourtForClub({
    required String clubId,
    required DateTime matchDate,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final courtsResponse = await _supabase
          .from('courts')
          .select('id')
          .eq('club_id', clubId)
          .eq('is_active', true);

      final courtIds =
          (courtsResponse as List).map((e) => e['id'] as String).toList();
      if (courtIds.isEmpty) return null;

      final conflictsResponse = await _supabase
          .from('matches')
          .select('court_id, scheduled_time, scheduled_end_time')
          .inFilter('court_id', courtIds)
          .eq('scheduled_date', matchDate.toIso8601String().split('T')[0])
          .inFilter('status', [
        MatchStatus.matched.value,
        MatchStatus.confirmed.value,
        MatchStatus.inProgress.value,
        MatchStatus.blocked.value
      ]);

      for (final courtId in courtIds) {
        bool hasConflict = false;
        for (final conflict in conflictsResponse as List) {
          if (conflict['court_id'] != courtId) continue;

          final cStartStr = conflict['scheduled_time'] as String?;
          final cEndStr = conflict['scheduled_end_time'] as String?;

          if (cStartStr != null &&
              _timesOverlap(
                  startTime, endTime, cStartStr, cEndStr ?? cStartStr)) {
            hasConflict = true;
            break;
          }
        }
        if (!hasConflict) return courtId;
      }
      return courtIds.first;
    } catch (e) {
      print('Error finding free court: \$e');
      return null;
    }
  }

  bool _timesOverlap(String start1, String end1, String start2, String end2) {
    try {
      final f = DateFormat("h:mm a");
      final s1 = f.parse(start1);
      final e1 = f.parse(end1);
      final s2 = f.parse(start2);
      final e2 = f.parse(end2);

      final d1s = DateTime(2000, 1, 1, s1.hour, s1.minute);
      DateTime d1e = DateTime(2000, 1, 1, e1.hour, e1.minute);
      if (d1e.isBefore(d1s) || d1e.isAtSameMomentAs(d1s)) {
        d1e = d1e.add(const Duration(days: 1));
      }

      final d2s = DateTime(2000, 1, 1, s2.hour, s2.minute);
      DateTime d2e = DateTime(2000, 1, 1, e2.hour, e2.minute);
      if (d2e.isBefore(d2s) || d2e.isAtSameMomentAs(d2s)) {
        d2e = d2e.add(const Duration(days: 1));
      }

      return d1s.isBefore(d2e) && d2s.isBefore(d1e);
    } catch (e) {
      return start1 == start2;
    }
  }
}
