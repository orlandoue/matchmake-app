import 'package:get/get.dart';
import 'package:orland_sports/models/match_model.dart';
import 'package:orland_sports/services/score_service.dart';

/// Controller for referee score tracking during a match
class ScoreController extends GetxController {
  static ScoreController get instance => Get.find<ScoreController>();

  final _scoreService = ScoreService.instance;

  // Current match being scored
  final Rx<MatchModel?> currentMatch = Rx<MatchModel?>(null);

  // Score data
  final RxMap<String, dynamic> scoreData = <String, dynamic>{}.obs;

  // Loading state
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  // Convenience getters
  int get player1PointsRaw => scoreData['player1_points'] as int? ?? 0;
  int get player2PointsRaw => scoreData['player2_points'] as int? ?? 0;

  String get player1Points => _formatPoints(player1PointsRaw);
  String get player2Points => _formatPoints(player2PointsRaw);

  String _formatPoints(int pts) {
    switch (pts) {
      case 0: return '0';
      case 1: return '15';
      case 2: return '30';
      case 3: return '40';
      case 4: return 'AD';
      default: return '0';
    }
  }
  int get player1GamesWon => scoreData['player1_games_won'] as int? ?? 0;
  int get player2GamesWon => scoreData['player2_games_won'] as int? ?? 0;
  int get player1SetsWon => scoreData['player1_sets_won'] as int? ?? 0;
  int get player2SetsWon => scoreData['player2_sets_won'] as int? ?? 0;
  int get player1Fouls => scoreData['player1_fouls'] as int? ?? 0;
  int get player2Fouls => scoreData['player2_fouls'] as int? ?? 0;
  int get currentSet => scoreData['current_set'] as int? ?? 1;
  String? get servicePlayer => scoreData['service_player'] as String?;
  List<dynamic> get sets => scoreData['sets'] as List<dynamic>? ?? [];

  /// Initialize score tracking for a match
  void initializeMatch(MatchModel match) {
    currentMatch.value = match;

    if (match.scoreData != null && match.scoreData!.isNotEmpty) {
      scoreData.assignAll(match.scoreData!);
    } else {
      scoreData.assignAll(_scoreService.buildInitialScoreData(match));
    }

    // Load the latest score from database to ensure data is current
    _loadLatestScore(match.id);
  }

  /// Fetch the latest score data from the database
  Future<void> _loadLatestScore(String matchId) async {
    try {
      final data = await _scoreService.getMatchScore(matchId);
      if (data != null && data.isNotEmpty) {
        scoreData.assignAll(data);
      }
    } catch (e) {
      print('Error loading latest score: $e');
    }
  }

  /// Add a point for player
  Future<void> addPointForPlayer(String playerId) async {
    if (currentMatch.value == null) return;

    final updated = _scoreService.addPoint(
      Map<String, dynamic>.from(scoreData),
      playerId,
      currentMatch.value!.player1Id,
    );
    scoreData.assignAll(updated);
    await _saveScore();
  }

  /// Add a game for player
  Future<void> addGameForPlayer(String playerId) async {
    if (currentMatch.value == null) return;

    final updated = _scoreService.addGame(
      Map<String, dynamic>.from(scoreData),
      playerId,
      currentMatch.value!.player1Id,
    );
    scoreData.assignAll(updated);
    await _saveScore();
  }

  /// Add a set for player
  Future<void> addSetForPlayer(String playerId) async {
    if (currentMatch.value == null) return;

    final updated = _scoreService.addSet(
      Map<String, dynamic>.from(scoreData),
      playerId,
      currentMatch.value!.player1Id,
    );
    scoreData.assignAll(updated);
    await _saveScore();
  }

  /// Add a foul for player
  Future<void> addFoulForPlayer(String playerId) async {
    if (currentMatch.value == null) return;

    final updated = _scoreService.addFoul(
      Map<String, dynamic>.from(scoreData),
      playerId,
      currentMatch.value!.player1Id,
    );
    scoreData.assignAll(updated);
    await _saveScore();
  }

  /// Subtract a point for player
  Future<void> subtractPointForPlayer(String playerId) async {
    if (currentMatch.value == null) return;

    final updated = _scoreService.subtractPoint(
      Map<String, dynamic>.from(scoreData),
      playerId,
      currentMatch.value!.player1Id,
    );
    scoreData.assignAll(updated);
    await _saveScore();
  }

  /// Subtract a game for player
  Future<void> subtractGameForPlayer(String playerId) async {
    if (currentMatch.value == null) return;

    final updated = _scoreService.subtractGame(
      Map<String, dynamic>.from(scoreData),
      playerId,
      currentMatch.value!.player1Id,
    );
    scoreData.assignAll(updated);
    await _saveScore();
  }

  /// Subtract a set for player
  Future<void> subtractSetForPlayer(String playerId) async {
    if (currentMatch.value == null) return;

    final updated = _scoreService.subtractSet(
      Map<String, dynamic>.from(scoreData),
      playerId,
      currentMatch.value!.player1Id,
    );
    scoreData.assignAll(updated);
    await _saveScore();
  }

  /// Subtract a foul for player
  Future<void> subtractFoulForPlayer(String playerId) async {
    if (currentMatch.value == null) return;

    final updated = _scoreService.subtractFoul(
      Map<String, dynamic>.from(scoreData),
      playerId,
      currentMatch.value!.player1Id,
    );
    scoreData.assignAll(updated);
    await _saveScore();
  }

  /// Toggle service player
  Future<void> toggleServicePlayer() async {
    if (currentMatch.value == null) return;

    final match = currentMatch.value!;
    if (match.player2Id == null) return;

    final updated = _scoreService.toggleService(
      Map<String, dynamic>.from(scoreData),
      match.player1Id,
      match.player2Id!,
    );
    scoreData.assignAll(updated);
    await _saveScore();
  }

  /// Get formatted score summary
  String get scoreSummary {
    return _scoreService.getScoreSummary(
      scoreData.isNotEmpty ? Map<String, dynamic>.from(scoreData) : null,
    );
  }

  /// Get score data as a regular map for saving
  Map<String, dynamic> get scoreDataMap => Map<String, dynamic>.from(scoreData);

  /// Save score to database
  Future<void> _saveScore() async {
    if (currentMatch.value == null) return;

    try {
      isSaving.value = true;
      await _scoreService.updateMatchScore(
        currentMatch.value!.id,
        Map<String, dynamic>.from(scoreData),
      );
    } catch (e) {
      print('Error saving score: $e');
    } finally {
      isSaving.value = false;
    }
  }

  /// Load existing score from database
  Future<void> loadScore(String matchId) async {
    try {
      isLoading.value = true;
      final data = await _scoreService.getMatchScore(matchId);
      if (data != null && data.isNotEmpty) {
        scoreData.assignAll(data);
      }
    } catch (e) {
      print('Error loading score: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset score data
  void resetScore() {
    if (currentMatch.value != null) {
      scoreData
          .assignAll(_scoreService.buildInitialScoreData(currentMatch.value!));
    } else {
      scoreData.clear();
    }
  }

  @override
  void onClose() {
    currentMatch.value = null;
    scoreData.clear();
    super.onClose();
  }
}
