import 'dart:math';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:orland_sports/const/supabase_tables.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/match_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for match-related operations
class MatchService {
  // Private constructor
  MatchService._privateConstructor();

  // Singleton instance variable
  static MatchService? _instance;

  // Getter to access the singleton instance
  static MatchService get instance {
    _instance ??= MatchService._privateConstructor();
    return _instance!;
  }

  final _supabase = Supabase.instance.client;

  // ==================== MATCH OPERATIONS ====================

  /// Create a new match
  Future<MatchModel?> createMatch(MatchModel match) async {
    try {
      final data = match.toInsertJson();

      // Generate invite code for friendly matches
      if (match.matchMode == MatchMode.friendly && match.inviteCode == null) {
        data['invite_code'] = _generateInviteCode();
      }

      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .insert(data)
          .select(_matchSelectQuery)
          .single();

      return MatchModel.fromJson(response);
    } catch (e) {
      print('Error creating match: $e');
      return null;
    }
  }

  /// Get match by ID with all related data
  Future<MatchModel?> getMatchById(String matchId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .select(_matchSelectQuery)
          .eq('id', matchId)
          .maybeSingle();

      if (response != null) {
        return MatchModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error getting match by ID: $e');
      return null;
    }
  }

  /// Get matches for a player
  Future<List<MatchModel>> getPlayerMatches(String playerId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .select(_matchSelectQuery)
          .or('player1_id.eq.$playerId,player2_id.eq.$playerId,player3_id.eq.$playerId,player4_id.eq.$playerId')
          .order('scheduled_date', ascending: true)
          .order('scheduled_time', ascending: true);

      return (response as List)
          .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting player matches: $e');
      return [];
    }
  }

  /// Get active matches for a player (not completed or cancelled)
  Future<List<MatchModel>> getPlayerActiveMatches(String playerId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .select(_matchSelectQuery)
          .or('player1_id.eq.$playerId,player2_id.eq.$playerId,player3_id.eq.$playerId,player4_id.eq.$playerId')
          .not('status', 'in', ['completed', 'cancelled'])
          .order('scheduled_date', ascending: true)
          .order('scheduled_time', ascending: true);

      return (response as List)
          .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting player active matches: $e');
      return [];
    }
  }

  /// Get matches for a referee
  Future<List<MatchModel>> getRefereeMatches(String refereeId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .select(_matchSelectQuery)
          .eq('referee_id', refereeId)
          .order('scheduled_date', ascending: true)
          .order('scheduled_time', ascending: true);

      return (response as List)
          .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting referee matches: $e');
      return [];
    }
  }

  /// Get matches available for any referee to claim (Uber model)
  /// Fetches matches with status 'matched' (players found) where no referee is assigned yet
  Future<List<MatchModel>> getRefereeAvailableMatches() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .select(_matchSelectQuery)
          .inFilter('status', [MatchStatus.matched.value, 'scheduled'])
          .isFilter('referee_id', null)
          .gte('scheduled_date', today)
          .order('scheduled_date', ascending: true)
          .order('scheduled_time', ascending: true);

      final allMatches = (response as List)
          .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return allMatches.where((match) {
        try {
          final now = DateTime.now();
          final format = DateFormat("h:mm a");
          final matchTime = format.parse(match.scheduledTime);
          final matchDateTime = DateTime(match.scheduledDate.year, match.scheduledDate.month, match.scheduledDate.day, matchTime.hour, matchTime.minute);
          if (matchDateTime.isBefore(now)) return false;
        } catch (e) {
          print('Error parsing match date/time for referee filter log: $e');
        }
        return true;
      }).toList();
    } catch (e) {
      print('Error getting available matches for referee: $e');
      return [];
    }
  }

  /// Get scheduled matches for a referee (confirmed and in_progress only, today or future)
  Future<List<MatchModel>> getRefereeScheduledMatches(String refereeId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .select(_matchSelectQuery)
          .eq('referee_id', refereeId)
          .inFilter('status', [
            MatchStatus.confirmed.value,
            MatchStatus.inProgress.value,
          ])
          .gte('scheduled_date', today)
          .order('scheduled_date', ascending: true)
          .order('scheduled_time', ascending: true);

      return (response as List)
          .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting referee scheduled matches: $e');
      return [];
    }
  }

  /// Get matches by court
  Future<List<MatchModel>> getMatchesByCourt(String courtId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .select(_matchSelectQuery)
          .eq('court_id', courtId)
          .order('scheduled_date', ascending: true)
          .order('scheduled_time', ascending: true);

      return (response as List)
          .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting matches by court: $e');
      return [];
    }
  }

  /// Get completed/cancelled matches for a referee (history)
  Future<List<MatchModel>> getRefereeCompletedMatches(String refereeId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .select(_matchSelectQuery)
          .eq('referee_id', refereeId)
          .inFilter('status', [
            MatchStatus.completed.value,
            MatchStatus.cancelled.value,
          ])
          .order('scheduled_date', ascending: false)
          .order('scheduled_time', ascending: false);

      return (response as List)
          .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting referee completed matches: $e');
      return [];
    }
  }

  /// Get all available matches that players can join (random matchmaking)
  /// These are matches waiting for opponents, excluding the current player's own matches
  Future<List<MatchModel>> getAvailableMatchesForPlayer(
      String currentPlayerId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .select(_matchSelectQuery)
          .eq('status', MatchStatus.waitingForOpponent.value)
          .neq('player1_id', currentPlayerId)
          .gte('scheduled_date', DateTime.now().toIso8601String().split('T')[0])
          .order('scheduled_date', ascending: true)
          .order('scheduled_time', ascending: true);

      // Filter out matches where the player is already a participant (player2/3/4)
      final allMatches = (response as List)
          .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return allMatches.where((match) {
        if (match.hasPlayer(currentPlayerId)) return false;
        
        // PRIVACY LOGIC: Hide 2v2 matches that are reserving player2_id for someone else
        if (match.matchType == MatchType.twoVsTwo && 
            match.invitedPlayer2Id != null && 
            match.player2Id == null) {
          return false;
        }
        
        // EXPERT TIME FILTER: Remove matches that have already started/expired
        try {
          final now = DateTime.now();
          final format = DateFormat("h:mm a");
          final matchTime = format.parse(match.scheduledTime);
          final matchDateTime = DateTime(match.scheduledDate.year, match.scheduledDate.month, match.scheduledDate.day, matchTime.hour, matchTime.minute);
          if (matchDateTime.isBefore(now)) return false;
        } catch (e) {
          print('Error checking match time expiration: $e');
        }

        return true;
      }).toList();
    } catch (e) {
      print('Error getting available matches for player: $e');
      return [];
    }
  }

  /// Get pending 2v2 partner invitations for the current player
  Future<List<MatchModel>> getPendingInvitations(String currentPlayerId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .select(_matchSelectQuery)
          .eq('invited_player2_id', currentPlayerId)
          .isFilter('player2_id', null) // Only where they haven't joined yet
          .inFilter('status', [
             MatchStatus.waitingForOpponent.value,
             MatchStatus.pending.value
          ])
          .gte('scheduled_date', DateTime.now().toIso8601String().split('T')[0])
          .order('scheduled_date', ascending: true);

      return (response as List)
          .map((json) => MatchModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting pending invitations: $e');
      return [];
    }
  }

  /// Check if a conflicting match exists at the same court/date/time
  /// Returns true if a conflict exists, false otherwise
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
          .select(_matchSelectQuery)
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
      final matches = (response as List).map((json) => MatchModel.fromJson(json)).toList();

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
          .select(_matchSelectQuery)
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
      final matches = (response as List)
          .map((json) => MatchModel.fromJson(json))
          .toList();

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

  /// Checks if an existing match's time fully falls inside the search window,
  /// or overlaps by at least 60 minutes for legacy flexibility.
  bool _isMatchWithinSearchWindow(MatchModel match, String? searchStartStr, String? searchEndTimeStr) {
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
      DateTime sStart = DateTime(baseDate.year, baseDate.month, baseDate.day, searchStart.hour, searchStart.minute);
      DateTime sEnd = DateTime(baseDate.year, baseDate.month, baseDate.day, searchEnd.hour, searchEnd.minute);
      if (sEnd.isBefore(sStart)) sEnd = sEnd.add(const Duration(days: 1));

      DateTime mStart = DateTime(baseDate.year, baseDate.month, baseDate.day, matchStart.hour, matchStart.minute);
      DateTime mEnd = DateTime(baseDate.year, baseDate.month, baseDate.day, matchEnd.hour, matchEnd.minute);
      if (mEnd.isBefore(mStart)) mEnd = mEnd.add(const Duration(days: 1));

      // 1. Fully contained
      bool isContained = (mStart.isAtSameMomentAs(sStart) || mStart.isAfter(sStart)) &&
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

  /// Join an existing match (single player)
  Future<MatchModel?> joinMatch(String matchId, String playerId) async {
    try {
      final match = await getMatchById(matchId);
      if (match == null) return null;

      Map<String, dynamic> updateData;

      if (match.matchType == MatchType.oneVsOne) {
        // For 1v1, player joins as player2
        updateData = {
          'player2_id': playerId,
          'status': MatchStatus.matched.value,
        };
      } else {
        // For 2v2, find empty slot
        if (match.player2Id == null) {
          updateData = {'player2_id': playerId};
        } else if (match.player3Id == null) {
          updateData = {'player3_id': playerId};
        } else if (match.player4Id == null) {
          updateData = {
            'player4_id': playerId,
            'status': MatchStatus.matched.value,
          };
        } else {
          return null; // Match is full
        }
      }

      if (updateData['status'] == MatchStatus.matched.value) {
        try {
          String? clubIdToSearch;
          if (match.preferredClubIds.isNotEmpty) {
            clubIdToSearch = match.preferredClubIds.first;
          }
          // Fijar horario de 1 hora y asignar cancha física
          if (clubIdToSearch != null) {
            final format = DateFormat("h:mm a");
            final baseDate = match.scheduledDate;
            
            // Intentar RPC para obtener el mejor slot
            String? fixedStartTime;
            String? fixedEndTime;
            
            try {
              final matchStart = format.parse(match.scheduledTime);
              final matchEndStr = match.scheduledEndTime ?? match.scheduledTime;
              final matchEnd = format.parse(matchEndStr);
              final startWin = DateTime(baseDate.year, baseDate.month, baseDate.day, matchStart.hour, matchStart.minute);
              final endWin = DateTime(baseDate.year, baseDate.month, baseDate.day, matchEnd.hour, matchEnd.minute);
              
              final bestIso = await findBestMatchSlot(
                clubId: clubIdToSearch,
                startWindowIso: startWin.toIso8601String(),
                endWindowIso: endWin.toIso8601String(),
                durationMinutes: 60,
              );
              if (bestIso != null) {
                final dtStart = DateTime.parse(bestIso);
                final dtEnd = dtStart.add(const Duration(minutes: 60));
                fixedStartTime = format.format(dtStart);
                fixedEndTime = format.format(dtEnd);
              }
            } catch (e) {
              print('RPC find_best_match_slot failed, using fallback: \$e');
            }
            
            // Fallback: usar el inicio del rango del partido como slot de 1h
            if (fixedStartTime == null) {
              try {
                final matchStart = format.parse(match.scheduledTime);
                final dtStart = DateTime(baseDate.year, baseDate.month, baseDate.day, matchStart.hour, matchStart.minute);
                final dtEnd = dtStart.add(const Duration(minutes: 60));
                fixedStartTime = format.format(dtStart);
                fixedEndTime = format.format(dtEnd);
              } catch (e) {
                print('Fallback time calculation failed: \$e');
              }
            }
            
            if (fixedStartTime != null && fixedEndTime != null) {
              updateData['scheduled_time'] = fixedStartTime;
              updateData['scheduled_end_time'] = fixedEndTime;
              
              final availableCourtId = await findFreeCourtForClub(
                clubId: clubIdToSearch,
                matchDate: baseDate,
                startTime: fixedStartTime,
                endTime: fixedEndTime,
              );
              if (availableCourtId != null) {
                updateData['court_id'] = availableCourtId;
              }
            }
          }
        } catch (e) {
          print('Error locking 1-hour schedule: $e');
        }
      }

      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .update(updateData)
          .eq('id', matchId)
          .select(_matchSelectQuery)
          .single();

      return MatchModel.fromJson(response);
    } catch (e) {
      print('Error joining match: $e');
      return null;
    }
  }

  /// Join an existing 2v2 match as a DUO (two players at once).
  ///
  /// Fills the next two consecutive empty slots in a single atomic UPDATE.
  /// Returns the updated [MatchModel] or null if less than 2 free slots exist.
  Future<MatchModel?> joinMatchAsDuo(
    String matchId,
    String player1Id,
    String player2Id,
  ) async {
    try {
      final match = await getMatchById(matchId);
      if (match == null) return null;

      // Must be a 2v2 match
      if (match.matchType != MatchType.twoVsTwo) {
        print('[joinMatchAsDuo] Target match is not 2v2');
        return null;
      }

      // Count free slots and map the duo to them
      final Map<String, dynamic> updateData = {};

      if (match.player2Id == null && match.player3Id == null) {
        // Slots P2 and P3 are both free → this duo fills them
        updateData['player2_id'] = player1Id;
        updateData['player3_id'] = player2Id;
      } else if (match.player3Id == null && match.player4Id == null) {
        // Slots P3 and P4 are both free
        updateData['player3_id'] = player1Id;
        updateData['player4_id'] = player2Id;
        // All 4 slots now filled → mark as matched
        updateData['status'] = MatchStatus.matched.value;
      } else if (match.player2Id == null && match.player4Id == null) {
        // Edge case: P2 and P4 free (P3 taken by someone)
        updateData['player2_id'] = player1Id;
        updateData['player4_id'] = player2Id;
        updateData['status'] = MatchStatus.matched.value;
      } else {
        print('[joinMatchAsDuo] Not enough free slots for a duo in match $matchId');
        return null; // Less than 2 consecutive free slots
      }

      if (updateData['status'] == MatchStatus.matched.value) {
        try {
          String? clubIdToSearch;
          if (match.preferredClubIds.isNotEmpty) {
            clubIdToSearch = match.preferredClubIds.first;
          }
          // Fijar horario de 1 hora y asignar cancha física (joinMatchAsDuo)
          if (clubIdToSearch != null) {
            final format = DateFormat("h:mm a");
            final baseDate = match.scheduledDate;
            
            String? fixedStartTime;
            String? fixedEndTime;
            
            try {
              final matchStart = format.parse(match.scheduledTime);
              final matchEndStr = match.scheduledEndTime ?? match.scheduledTime;
              final matchEnd = format.parse(matchEndStr);
              final startWin = DateTime(baseDate.year, baseDate.month, baseDate.day, matchStart.hour, matchStart.minute);
              final endWin = DateTime(baseDate.year, baseDate.month, baseDate.day, matchEnd.hour, matchEnd.minute);
              
              final bestIso = await findBestMatchSlot(
                clubId: clubIdToSearch,
                startWindowIso: startWin.toIso8601String(),
                endWindowIso: endWin.toIso8601String(),
                durationMinutes: 60,
              );
              if (bestIso != null) {
                final dtStart = DateTime.parse(bestIso);
                final dtEnd = dtStart.add(const Duration(minutes: 60));
                fixedStartTime = format.format(dtStart);
                fixedEndTime = format.format(dtEnd);
              }
            } catch (e) {
              print('RPC find_best_match_slot failed (duo), using fallback: $e');
            }
            
            // Fallback: usar inicio del partido como slot de 1h
            if (fixedStartTime == null) {
              try {
                final matchStart = format.parse(match.scheduledTime);
                final dtStart = DateTime(baseDate.year, baseDate.month, baseDate.day, matchStart.hour, matchStart.minute);
                final dtEnd = dtStart.add(const Duration(minutes: 60));
                fixedStartTime = format.format(dtStart);
                fixedEndTime = format.format(dtEnd);
              } catch (e) {
                print('Fallback time calculation failed (duo): $e');
              }
            }
            
            if (fixedStartTime != null && fixedEndTime != null) {
              updateData['scheduled_time'] = fixedStartTime;
              updateData['scheduled_end_time'] = fixedEndTime;
              
              final availableCourtId = await findFreeCourtForClub(
                clubId: clubIdToSearch,
                matchDate: baseDate,
                startTime: fixedStartTime,
                endTime: fixedEndTime,
              );
              if (availableCourtId != null) {
                updateData['court_id'] = availableCourtId;
              }
            }
          }
        } catch (e) {
          print('Error locking 1-hour schedule: $e');
        }
      }

      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .update(updateData)
          .eq('id', matchId)
          .select(_matchSelectQuery)
          .single();

      return MatchModel.fromJson(response);
    } catch (e) {
      print('Error joining match as duo: $e');
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
          .select(_matchSelectQuery)
          .isFilter('court_id', null)
          .eq('scheduled_date', scheduledDate.toIso8601String().split('T')[0])
          .eq('match_type', MatchType.twoVsTwo.value)
          .eq('match_mode', MatchMode.competitive.value)
          .eq('status', MatchStatus.waitingForOpponent.value)
          .neq('player1_id', currentPlayerId)
          .neq('player1_id', partnerId)
          .limit(50);

      final matches = (response as List)
          .map((json) => MatchModel.fromJson(json))
          .toList();

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
        final hasOverlap = match.preferredClubIds.any((id) => clubIds.contains(id));
        if (hasOverlap) return match;
      }
      return null;
    } catch (e) {
      print('Error finding match for duo: $e');
      return null;
    }
  }


  /// Join match by invite code
  Future<MatchModel?> joinMatchByCode(
      String inviteCode, String playerId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .select(_matchSelectQuery)
          .eq('invite_code', inviteCode.toUpperCase())
          .eq('status', MatchStatus.waitingForOpponent.value)
          .maybeSingle();

      if (response == null) return null;

      final match = MatchModel.fromJson(response);
      return joinMatch(match.id, playerId);
    } catch (e) {
      print('Error joining match by code: $e');
      return null;
    }
  }

  /// Update match status
  Future<MatchModel?> updateMatchStatus(
      String matchId, MatchStatus status) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .update({'status': status.value})
          .eq('id', matchId)
          .select(_matchSelectQuery)
          .single();

      return MatchModel.fromJson(response);
    } catch (e) {
      print('Error updating match status: $e');
      return null;
    }
  }

  /// Assign referee to match (only for today or future matches)
  Future<MatchModel?> assignReferee(String matchId, String refereeId) async {
    try {
      // Verify match is not in the past before assigning
      final matchData = await getMatchById(matchId);
      if (matchData != null && matchData.isPastMatch) {
        print('Cannot assign referee to past match: $matchId');
        return null;
      }

      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .update({
            'referee_id': refereeId,
            'status': MatchStatus.confirmed.value,
          })
          .eq('id', matchId)
          .select(_matchSelectQuery)
          .single();

      return MatchModel.fromJson(response);
    } catch (e) {
      print('Error assigning referee: $e');
      return null;
    }
  }

  /// Claim a match (Gig Economy Model)
  /// Uses a condition to ensure the match is still orphan (atomic check)
  Future<MatchModel?> claimMatch(String matchId, String refereeId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .update({
            'referee_id': refereeId,
            'status': MatchStatus.confirmed.value,
          })
          .eq('id', matchId)
          .isFilter('referee_id', null) // Critical for race conditions
          .select(_matchSelectQuery)
          .maybeSingle();

      if (response != null) {
        return MatchModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error claiming match: $e');
      return null;
    }
  }

  /// Update check-in status for players
  Future<MatchModel?> updateCheckInStatus(String matchId,
      {bool? player1CheckedIn,
      bool? player2CheckedIn,
      bool? player3CheckedIn,
      bool? player4CheckedIn}) async {
    try {
      final Map<String, dynamic> updateData = {};
      if (player1CheckedIn != null) {
        updateData['player1_checked_in'] = player1CheckedIn;
      }
      if (player2CheckedIn != null) {
        updateData['player2_checked_in'] = player2CheckedIn;
      }
      if (player3CheckedIn != null) {
        updateData['player3_checked_in'] = player3CheckedIn;
      }
      if (player4CheckedIn != null) {
        updateData['player4_checked_in'] = player4CheckedIn;
      }

      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .update(updateData)
          .eq('id', matchId)
          .select(_matchSelectQuery)
          .single();

      return MatchModel.fromJson(response);
    } catch (e) {
      print('Error updating check-in status: $e');
      return null;
    }
  }

  /// Start a match
  Future<MatchModel?> startMatch(String matchId) async {
    return updateMatchStatus(matchId, MatchStatus.inProgress);
  }

  /// Complete a match with winner or draw using atomic RPC
  Future<MatchModel?> completeMatch(String matchId,
      {String? winnerId, Map<String, dynamic>? scoreData}) async {
    try {
      // Reward amount is fixed at 5000 CLP for now as requested
      const int refereeReward = 5000;

      final pScoreData = scoreData ?? {};
      
      print('🚀 [MatchService] DEBUG: Sending complete_match_and_update_stats RPC');
      print('📦 [MatchService] p_match_id: $matchId');
      print('👑 [MatchService] p_winner_id: $winnerId');
      print('📊 [MatchService] p_score_data: ${jsonEncode(pScoreData)}');
      print('💰 [MatchService] p_referee_reward: $refereeReward');

      // Call the Supabase RPC function
      await _supabase.rpc('complete_match_and_update_stats', params: {
        'p_match_id': matchId,
        'p_winner_id': winnerId,
        'p_score_data': pScoreData,
        'p_referee_reward': refereeReward,
      });

      print('✅ [MatchService] RPC Success!');

      // Fetch the updated match to return
      return await getMatchById(matchId);
    } catch (e) {
      print('❌ [MatchService] ERROR RPC FINISH MATCH: $e');
      rethrow; // Rethrow to let the controller handle UI feedback
    }
  }

  /// Cancel a match
  Future<bool> cancelMatch(String matchId) async {
    try {
      await _supabase
          .from(SupabaseTables.matchesTable)
          .update({'status': MatchStatus.cancelled.value}).eq('id', matchId);
      return true;
    } catch (e) {
      print('Error cancelling match: $e');
      return false;
    }
  }

  /// Get referee for a court
  Future<String?> getRefereeForCourt(String courtId) async {
    // SILENCED: Table 'court_assignments' is deprecated
    /*
    try {
      final response = await _supabase
          .from(SupabaseTables.courtAssignmentsTable)
          .select('referee_id')
          .eq('court_id', courtId)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        return response['referee_id'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting referee for court: $e');
      return null;
    }
    */
    return null;
  }

  /// Subscribe to match updates
  RealtimeChannel subscribeToMatch(
      String matchId, Function(MatchModel) onUpdate) {
    return _supabase
        .channel('match_$matchId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabaseTables.matchesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: matchId,
          ),
          callback: (payload) async {
            final match = await getMatchById(matchId);
            if (match != null) {
              onUpdate(match);
            }
          },
        )
        .subscribe();
  }

  /// Subscribe to referee's matches (for notifications)
  /// [onNewMatch] is called only for newly inserted matches at the referee's courts.
  /// [onMatchUpdated] is called for status/score updates (no toast).
  RealtimeChannel subscribeToRefereeMatches(
    String refereeId, {
    required Function(MatchModel) onNewMatch,
    Function()? onMatchUpdated,
  }) {
    return _supabase
        .channel('referee_matches_$refereeId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseTables.matchesTable,
          callback: (payload) async {
            if (payload.eventType == PostgresChangeEvent.insert) {
              // Only show "New Match" toast for genuinely new matches
              if (payload.newRecord.isNotEmpty) {
                final matchData = payload.newRecord;
                final refereeForCourt =
                    await getRefereeForCourt(matchData['court_id']);
                if (refereeForCourt == refereeId) {
                  final match = await getMatchById(matchData['id']);
                  if (match != null) {
                    onNewMatch(match);
                  }
                }
              }
            } else if (payload.eventType == PostgresChangeEvent.update) {
              // For updates (score changes, status changes), refresh silently
              onMatchUpdated?.call();
            }
          },
        )
        .subscribe();
  }

  /// Subscribe to available matches for players
  RealtimeChannel subscribeToAvailableMatches(
      String currentPlayerId, Function() onMatchesChanged) {
    return _supabase
        .channel('available_matches_$currentPlayerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseTables.matchesTable,
          callback: (payload) async {
            // Refresh available matches when any match is created, updated, or deleted
            // This ensures the list stays up to date
            if (payload.eventType == PostgresChangeEvent.insert) {
              final matchData = payload.newRecord;
              // Trigger refresh for any waiting match that the player can join
              if (matchData['status'] == MatchStatus.waitingForOpponent.value &&
                  matchData['player1_id'] != currentPlayerId) {
                print('🔔 New available match detected, refreshing list...');
                onMatchesChanged();
              }
            } else if (payload.eventType == PostgresChangeEvent.update ||
                payload.eventType == PostgresChangeEvent.delete) {
              // Refresh on update/delete as well (match might have been filled or cancelled)
              print(
                  '🔄 Match updated/deleted, refreshing available matches...');
              onMatchesChanged();
            }
          },
        )
        .subscribe();
  }

  /// Generate unique invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Select query for matches with all relations
  String get _matchSelectQuery => '''
    *,
    courts(*, sports(*)),
    player1:users!matches_player1_id_fkey(*),
    player2:users!matches_player2_id_fkey(*),
    player3:users!matches_player3_id_fkey(*),
    player4:users!matches_player4_id_fkey(*),
    referee:users!matches_referee_id_fkey(*)
  ''';

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

      final courtIds = (courtsResponse as List).map((e) => e['id'] as String).toList();
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
          
          if (cStartStr != null && _timesOverlap(startTime, endTime, cStartStr, cEndStr ?? cStartStr)) {
            hasConflict = true;
            break;
          }
        }
        if (!hasConflict) return courtId; 
      }
      return courtIds.first; 
    } catch(e) {
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
      if (d1e.isBefore(d1s) || d1e.isAtSameMomentAs(d1s)) d1e = d1e.add(const Duration(days: 1));
      
      final d2s = DateTime(2000, 1, 1, s2.hour, s2.minute);
      DateTime d2e = DateTime(2000, 1, 1, e2.hour, e2.minute);
      if (d2e.isBefore(d2s) || d2e.isAtSameMomentAs(d2s)) d2e = d2e.add(const Duration(days: 1));
      
      return d1s.isBefore(d2e) && d2s.isBefore(d1e);
    } catch(e) {
      return start1 == start2;
    }
  }
}
