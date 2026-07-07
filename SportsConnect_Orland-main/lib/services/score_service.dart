import 'package:orland_sports/const/supabase_tables.dart';
import 'package:orland_sports/models/match_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for score tracking operations
class ScoreService {
  ScoreService._privateConstructor();

  static ScoreService? _instance;

  static ScoreService get instance {
    _instance ??= ScoreService._privateConstructor();
    return _instance!;
  }

  final _supabase = Supabase.instance.client;

  /// Update match score data
  Future<bool> updateMatchScore(
    String matchId,
    Map<String, dynamic> scoreData,
  ) async {
    try {
      await _supabase
          .from(SupabaseTables.matchesTable)
          .update({'score_data': scoreData}).eq('id', matchId);
      return true;
    } catch (e) {
      print('Error updating match score: $e');
      return false;
    }
  }

  /// Get match score data
  Future<Map<String, dynamic>?> getMatchScore(String matchId) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.matchesTable)
          .select('score_data')
          .eq('id', matchId)
          .maybeSingle();

      if (response != null) {
        return response['score_data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting match score: $e');
      return null;
    }
  }

  /// Build initial score data structure for a match
  Map<String, dynamic> buildInitialScoreData(MatchModel match) {
    return {
      'sets': <Map<String, dynamic>>[],
      'current_set': 1,
      'player1_sets_won': 0,
      'player2_sets_won': 0,
      'player1_games_won': 0,
      'player2_games_won': 0,
      'player1_points': 0,
      'player2_points': 0,
      'player1_fouls': 0,
      'player2_fouls': 0,
      'service_player': match.player1Id,
    };
  }

  /// Add a point for a player (Tennis/Padel logic: 15, 30, 40, AD, Game)
  Map<String, dynamic> addPoint(
    Map<String, dynamic> currentScore,
    String playerId,
    String player1Id,
  ) {
    final isPlayer1 = playerId == player1Id;
    final myKey = isPlayer1 ? 'player1_points' : 'player2_points';
    final otherKey = isPlayer1 ? 'player2_points' : 'player1_points';
    Map<String, dynamic> updatedScore = Map<String, dynamic>.from(currentScore);
    
    int myPoints = updatedScore[myKey] as int? ?? 0;
    int otherPoints = updatedScore[otherKey] as int? ?? 0;

    // Point representation: 0=0, 1=15, 2=30, 3=40, 4=AD
    if (myPoints == 3 && otherPoints == 4) {
      // Opponent has AD, we win point -> Return to Deuce (40-40, which is 3-3)
      updatedScore[otherKey] = 3;
    } else if (myPoints == 3 && otherPoints < 3) {
      // We have 40, they have < 40, we win point -> Win game!
      updatedScore = addGame(updatedScore, playerId, player1Id);
      updatedScore['player1_points'] = 0;
      updatedScore['player2_points'] = 0;
    } else if (myPoints == 4) {
      // We have AD, we win point -> Win game!
      updatedScore = addGame(updatedScore, playerId, player1Id);
      updatedScore['player1_points'] = 0;
      updatedScore['player2_points'] = 0;
    } else {
      // Normal point increment
      updatedScore[myKey] = myPoints + 1;
    }

    return updatedScore;
  }

  /// Subtract a point for a player
  Map<String, dynamic> subtractPoint(
    Map<String, dynamic> currentScore,
    String playerId,
    String player1Id,
  ) {
    final isPlayer1 = playerId == player1Id;
    final myKey = isPlayer1 ? 'player1_points' : 'player2_points';
    final updatedScore = Map<String, dynamic>.from(currentScore);
    
    int myPoints = updatedScore[myKey] as int? ?? 0;
    if (myPoints > 0) {
      updatedScore[myKey] = myPoints - 1;
    }
    return updatedScore;
  }

  /// Add a game won for a player
  Map<String, dynamic> addGame(
    Map<String, dynamic> currentScore,
    String playerId,
    String player1Id,
  ) {
    final isPlayer1 = playerId == player1Id;
    final key = isPlayer1 ? 'player1_games_won' : 'player2_games_won';
    final updatedScore = Map<String, dynamic>.from(currentScore);
    updatedScore[key] = (updatedScore[key] as int? ?? 0) + 1;
    return updatedScore;
  }

  /// Subtract a game won for a player
  Map<String, dynamic> subtractGame(
    Map<String, dynamic> currentScore,
    String playerId,
    String player1Id,
  ) {
    final isPlayer1 = playerId == player1Id;
    final key = isPlayer1 ? 'player1_games_won' : 'player2_games_won';
    final updatedScore = Map<String, dynamic>.from(currentScore);
    int games = updatedScore[key] as int? ?? 0;
    if (games > 0) {
      updatedScore[key] = games - 1;
    }
    return updatedScore;
  }

  /// Add a set won for a player
  Map<String, dynamic> addSet(
    Map<String, dynamic> currentScore,
    String playerId,
    String player1Id,
  ) {
    final isPlayer1 = playerId == player1Id;
    final key = isPlayer1 ? 'player1_sets_won' : 'player2_sets_won';
    final updatedScore = Map<String, dynamic>.from(currentScore);
    updatedScore[key] = (updatedScore[key] as int? ?? 0) + 1;

    // Record set in sets history
    final sets =
        List<Map<String, dynamic>>.from(updatedScore['sets'] as List? ?? []);
    sets.add({
      'set_number': updatedScore['current_set'],
      'player1_games': updatedScore['player1_games_won'],
      'player2_games': updatedScore['player2_games_won'],
    });
    updatedScore['sets'] = sets;
    updatedScore['current_set'] = (updatedScore['current_set'] as int) + 1;
    updatedScore['player1_games_won'] = 0;
    updatedScore['player2_games_won'] = 0;
    return updatedScore;
  }

  /// Subtract a set won for a player
  Map<String, dynamic> subtractSet(
    Map<String, dynamic> currentScore,
    String playerId,
    String player1Id,
  ) {
    final isPlayer1 = playerId == player1Id;
    final key = isPlayer1 ? 'player1_sets_won' : 'player2_sets_won';
    final updatedScore = Map<String, dynamic>.from(currentScore);
    int setsWon = updatedScore[key] as int? ?? 0;
    if (setsWon > 0) {
      updatedScore[key] = setsWon - 1;
      
      // Try to gracefully revert the last set if it existed in the history
      final sets = List<Map<String, dynamic>>.from(updatedScore['sets'] as List? ?? []);
      if (sets.isNotEmpty) {
        sets.removeLast();
        updatedScore['sets'] = sets;
        updatedScore['current_set'] = (updatedScore['current_set'] as int) > 1 ? (updatedScore['current_set'] as int) - 1 : 1;
      }
    }
    return updatedScore;
  }

  /// Add a foul for a player
  Map<String, dynamic> addFoul(
    Map<String, dynamic> currentScore,
    String playerId,
    String player1Id,
  ) {
    final isPlayer1 = playerId == player1Id;
    final key = isPlayer1 ? 'player1_fouls' : 'player2_fouls';
    final updatedScore = Map<String, dynamic>.from(currentScore);
    updatedScore[key] = (updatedScore[key] as int? ?? 0) + 1;
    return updatedScore;
  }

  /// Subtract a foul for a player
  Map<String, dynamic> subtractFoul(
    Map<String, dynamic> currentScore,
    String playerId,
    String player1Id,
  ) {
    final isPlayer1 = playerId == player1Id;
    final key = isPlayer1 ? 'player1_fouls' : 'player2_fouls';
    final updatedScore = Map<String, dynamic>.from(currentScore);
    int fouls = updatedScore[key] as int? ?? 0;
    if (fouls > 0) {
      updatedScore[key] = fouls - 1;
    }
    return updatedScore;
  }

  /// Toggle service player
  Map<String, dynamic> toggleService(
    Map<String, dynamic> currentScore,
    String player1Id,
    String player2Id,
  ) {
    final updatedScore = Map<String, dynamic>.from(currentScore);
    final currentService = updatedScore['service_player'] as String?;
    updatedScore['service_player'] =
        currentService == player1Id ? player2Id : player1Id;
    return updatedScore;
  }

  /// Finalize score data before completing a match.
  /// Captures the current set's game scores if any games were played.
  Map<String, dynamic> finalizeScoreData(Map<String, dynamic> scoreData) {
    final updated = Map<String, dynamic>.from(scoreData);
    final p1Games = updated['player1_games_won'] as int? ?? 0;
    final p2Games = updated['player2_games_won'] as int? ?? 0;

    // If there are unsaved games in the current set, record them
    if (p1Games > 0 || p2Games > 0) {
      final sets =
          List<Map<String, dynamic>>.from(updated['sets'] as List? ?? []);
      sets.add({
        'set_number': updated['current_set'] ?? (sets.length + 1),
        'player1_games': p1Games,
        'player2_games': p2Games,
      });
      updated['sets'] = sets;

      // Determine set winner
      if (p1Games > p2Games) {
        updated['player1_sets_won'] =
            (updated['player1_sets_won'] as int? ?? 0) + 1;
      } else if (p2Games > p1Games) {
        updated['player2_sets_won'] =
            (updated['player2_sets_won'] as int? ?? 0) + 1;
      }

      // Reset current set games
      updated['player1_games_won'] = 0;
      updated['player2_games_won'] = 0;
      updated['current_set'] = (updated['current_set'] as int? ?? 1) + 1;
    }

    return updated;
  }

  /// Get formatted score summary for display
  String getScoreSummary(Map<String, dynamic>? scoreData) {
    if (scoreData == null) return 'No score data';

    final p1Sets = scoreData['player1_sets_won'] as int? ?? 0;
    final p2Sets = scoreData['player2_sets_won'] as int? ?? 0;
    final p1Games = scoreData['player1_games_won'] as int? ?? 0;
    final p2Games = scoreData['player2_games_won'] as int? ?? 0;

    final sets = scoreData['sets'] as List<dynamic>? ?? [];

    if (sets.isEmpty && p1Games == 0 && p2Games == 0) {
      return 'Match not started';
    }

    final buffer = StringBuffer();
    for (final set in sets) {
      final s = set as Map<String, dynamic>;
      buffer.write('${s['player1_games']}-${s['player2_games']} ');
    }

    if (p1Games > 0 || p2Games > 0) {
      buffer.write('($p1Games-$p2Games)');
    }

    return 'Sets: $p1Sets-$p2Sets  $buffer';
  }
}
