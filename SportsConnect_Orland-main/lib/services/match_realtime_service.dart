import 'package:orland_sports/const/supabase_tables.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/match_model.dart';
import 'package:orland_sports/services/match_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Realtime (Postgres changes) subscriptions for matches.
///
/// Owns every live channel the app opens on the `matches` table: a single
/// match, a referee's feed, and the player-facing available-matches feed.
/// Hydration of the changed row is delegated to [MatchService.getMatchById].
class MatchRealtimeService {
  MatchRealtimeService._privateConstructor();

  static MatchRealtimeService? _instance;

  static MatchRealtimeService get instance {
    _instance ??= MatchRealtimeService._privateConstructor();
    return _instance!;
  }

  final _supabase = Supabase.instance.client;
  final _matchService = MatchService.instance;

  /// Subscribe to a single match's updates.
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
            final match = await _matchService.getMatchById(matchId);
            if (match != null) {
              onUpdate(match);
            }
          },
        )
        .subscribe();
  }

  /// Subscribe to referee's matches (for notifications).
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
                    await _matchService.getRefereeForCourt(matchData['court_id']);
                if (refereeForCourt == refereeId) {
                  final match = await _matchService.getMatchById(matchData['id']);
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

  /// Subscribe to available matches for players.
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
              print('🔄 Match updated/deleted, refreshing available matches...');
              onMatchesChanged();
            }
          },
        )
        .subscribe();
  }
}
