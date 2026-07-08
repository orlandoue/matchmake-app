import 'dart:math';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:orland_sports/const/supabase_tables.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/match_model.dart';
import 'package:orland_sports/services/match_queries.dart';
import 'package:orland_sports/services/matchmaking_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// CRUD & lifecycle operations for matches.
///
/// Reads and writes match rows: create, fetch (player/referee/court views),
/// join, status transitions, check-in, claim, complete and cancel. Search and
/// slot-finding live in [MatchmakingService]; realtime lives in
/// MatchRealtimeService.
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
  final _matchmaking = MatchmakingService.instance;

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
          .select(kMatchSelectQuery)
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
          .select(kMatchSelectQuery)
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
          .select(kMatchSelectQuery)
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
          .select(kMatchSelectQuery)
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
          .select(kMatchSelectQuery)
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
          .select(kMatchSelectQuery)
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
          final matchDateTime = DateTime(
              match.scheduledDate.year,
              match.scheduledDate.month,
              match.scheduledDate.day,
              matchTime.hour,
              matchTime.minute);
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
          .select(kMatchSelectQuery)
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
          .select(kMatchSelectQuery)
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
          .select(kMatchSelectQuery)
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
          .select(kMatchSelectQuery)
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
          final matchDateTime = DateTime(
              match.scheduledDate.year,
              match.scheduledDate.month,
              match.scheduledDate.day,
              matchTime.hour,
              matchTime.minute);
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
          .select(kMatchSelectQuery)
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
        await _applyMatchedSchedule(match, updateData);
      }

      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .update(updateData)
          .eq('id', matchId)
          .select(kMatchSelectQuery)
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
        print(
            '[joinMatchAsDuo] Not enough free slots for a duo in match $matchId');
        return null; // Less than 2 consecutive free slots
      }

      if (updateData['status'] == MatchStatus.matched.value) {
        await _applyMatchedSchedule(match, updateData);
      }

      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .update(updateData)
          .eq('id', matchId)
          .select(kMatchSelectQuery)
          .single();

      return MatchModel.fromJson(response);
    } catch (e) {
      print('Error joining match as duo: $e');
      return null;
    }
  }

  /// When a match becomes `matched`, lock a 1-hour slot and assign a physical
  /// court for geo-routed matches. Mutates [updateData] in place.
  Future<void> _applyMatchedSchedule(
      MatchModel match, Map<String, dynamic> updateData) async {
    try {
      String? clubIdToSearch;
      if (match.preferredClubIds.isNotEmpty) {
        clubIdToSearch = match.preferredClubIds.first;
      }
      if (clubIdToSearch == null) return;

      final format = DateFormat("h:mm a");
      final baseDate = match.scheduledDate;

      String? fixedStartTime;
      String? fixedEndTime;

      try {
        final matchStart = format.parse(match.scheduledTime);
        final matchEndStr = match.scheduledEndTime ?? match.scheduledTime;
        final matchEnd = format.parse(matchEndStr);
        final startWin = DateTime(baseDate.year, baseDate.month, baseDate.day,
            matchStart.hour, matchStart.minute);
        final endWin = DateTime(baseDate.year, baseDate.month, baseDate.day,
            matchEnd.hour, matchEnd.minute);

        final bestIso = await _matchmaking.findBestMatchSlot(
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
        print('RPC find_best_match_slot failed, using fallback: $e');
      }

      // Fallback: usar el inicio del rango del partido como slot de 1h
      if (fixedStartTime == null) {
        try {
          final matchStart = format.parse(match.scheduledTime);
          final dtStart = DateTime(baseDate.year, baseDate.month, baseDate.day,
              matchStart.hour, matchStart.minute);
          final dtEnd = dtStart.add(const Duration(minutes: 60));
          fixedStartTime = format.format(dtStart);
          fixedEndTime = format.format(dtEnd);
        } catch (e) {
          print('Fallback time calculation failed: $e');
        }
      }

      if (fixedStartTime != null && fixedEndTime != null) {
        updateData['scheduled_time'] = fixedStartTime;
        updateData['scheduled_end_time'] = fixedEndTime;

        final availableCourtId = await _matchmaking.findFreeCourtForClub(
          clubId: clubIdToSearch,
          matchDate: baseDate,
          startTime: fixedStartTime,
          endTime: fixedEndTime,
        );
        if (availableCourtId != null) {
          updateData['court_id'] = availableCourtId;
        }
      }
    } catch (e) {
      print('Error locking 1-hour schedule: $e');
    }
  }

  /// Join match by invite code
  Future<MatchModel?> joinMatchByCode(
      String inviteCode, String playerId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .select(kMatchSelectQuery)
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
          .select(kMatchSelectQuery)
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
          .select(kMatchSelectQuery)
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
          .select(kMatchSelectQuery)
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
          .select(kMatchSelectQuery)
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
    return null;
  }

  /// Generate unique invite code
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }
}
