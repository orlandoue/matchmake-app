import 'dart:async';
import 'package:get/get.dart';
import 'package:orland_sports/controllers/referee_match_controller.dart';
import 'package:orland_sports/models/match_model.dart';

class ScoreboardController extends GetxController {
  final MatchModel match;
  
  ScoreboardController({required this.match});

  final RxInt matchTimeSeconds = 0.obs;
  Timer? _timer;

  // Real score memory (to keep history of sets)
  final RxList<int> team1SetsScore = <int>[].obs; // [6, 4, 7]
  final RxList<int> team2SetsScore = <int>[].obs; // [3, 6, 6]

  // Current state
  final RxInt currentTeam1Games = 0.obs;
  final RxInt currentTeam2Games = 0.obs;

  // Points (Numerical 0, 15, 30, 40, Adv) 
  // In tiebreak, it's 1, 2, 3...
  final RxInt currentTeam1PointsRaw = 0.obs;
  final RxInt currentTeam2PointsRaw = 0.obs;

  // Logic flags
  final RxBool isTieBreak = false.obs;

  @override
  void onInit() {
    super.onInit();
    startTimer();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      matchTimeSeconds.value++;
    });
  }

  String get formattedTimeText {
    final s = matchTimeSeconds.value;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  bool get isTennis => match.sportId == '00000000-0000-0000-0000-000000000002'; 
  bool get isPadel => !isTennis; 

  String getPointText(int team) {
    if (isTieBreak.value) {
      return team == 1 ? currentTeam1PointsRaw.value.toString() : currentTeam2PointsRaw.value.toString();
    }
    
    int pts = team == 1 ? currentTeam1PointsRaw.value : currentTeam2PointsRaw.value;
    switch (pts) {
      case 0: return '0';
      case 1: return '15';
      case 2: return '30';
      case 3: return '40';
      case 4: return 'Adv';
      default: return '0';
    }
  }

  void addPoint(int team) {
    if (team == 1) {
      _processPoint(1);
    } else {
      _processPoint(2);
    }
  }

  void _processPoint(int teamScorer) {
    final bool isT1 = teamScorer == 1;

    // TIE BREAK LOGIC
    if (isTieBreak.value) {
      if (isT1) currentTeam1PointsRaw.value++;
      else currentTeam2PointsRaw.value++;

      final pts1 = currentTeam1PointsRaw.value;
      final pts2 = currentTeam2PointsRaw.value;

      // Tie break ends at 7 with diff 2
      if ((pts1 >= 7 || pts2 >= 7) && (pts1 - pts2).abs() >= 2) {
         _winGame(teamScorer);
      }
      return;
    }

    // NORMAL LOGIC
    if (isT1) currentTeam1PointsRaw.value++;
    else currentTeam2PointsRaw.value++;

    final pts1 = currentTeam1PointsRaw.value;
    final pts2 = currentTeam2PointsRaw.value;

    if (isPadel) {
      // Golden Point (No Advantage)
      if (pts1 == 4 || pts2 == 4) {
         _winGame(teamScorer);
      }
    } else {
      // Tennis (Advantage)
      if (pts1 == 4 && pts2 == 4) {
        // Deuce reached via dropping Adv. Back to 40-40 (which is raw point = 3)
        currentTeam1PointsRaw.value = 3;
        currentTeam2PointsRaw.value = 3;
      } else if (pts1 == 4 && pts2 < 3) {
        _winGame(1);
      } else if (pts2 == 4 && pts1 < 3) {
        _winGame(2);
      } else if (pts1 >= 5 && (pts1 - pts2) >= 2) {
        _winGame(1);
      } else if (pts2 >= 5 && (pts2 - pts1) >= 2) {
        _winGame(2);
      }
    }
  }

  void _winGame(int team) {
    // Reset point counters
    currentTeam1PointsRaw.value = 0;
    currentTeam2PointsRaw.value = 0;

    if (team == 1) currentTeam1Games.value++;
    else currentTeam2Games.value++;

    final g1 = currentTeam1Games.value;
    final g2 = currentTeam2Games.value;

    // If it was a tiebreak point that triggered winGame
    if (isTieBreak.value) {
       _winSet(team);
       return;
    }

    // Check Set Win normal
    if ((g1 >= 6 || g2 >= 6) && (g1 - g2).abs() >= 2) {
       _winSet(team);
    } else if (g1 == 6 && g2 == 6) {
       // Normal Tie break triggered!
       isTieBreak.value = true;
    }
  }

  void _winSet(int team) {
    team1SetsScore.add(currentTeam1Games.value);
    team2SetsScore.add(currentTeam2Games.value);

    // Reset games
    currentTeam1Games.value = 0;
    currentTeam2Games.value = 0;
    isTieBreak.value = false;

    // Check match win
    int t1SetWins = 0;
    int t2SetWins = 0;
    for (int i=0; i < team1SetsScore.length; i++) {
      if (team1SetsScore[i] > team2SetsScore[i]) t1SetWins++;
      else t2SetWins++;
    }

    if (isTennis) {
      // 1 Set Match
      if (t1SetWins == 1) _promptMatchEnd(match.player1Id);
      else if (t2SetWins == 1) _promptMatchEnd(match.player2Id ?? 'team2'); 
    } else {
      // Padel Best of 3
      if (t1SetWins == 2) _promptMatchEnd(match.player1Id);
      else if (t2SetWins == 2) _promptMatchEnd(match.player2Id ?? 'team2');
      else if (t1SetWins == 1 && t2SetWins == 1) {
         // Activate super tie-break for third set automatically
         isTieBreak.value = true;
         // In a super tiebreak we technically just count points until 7, 
         // which is handled exactly the same by `isTieBreak` flag
      }
    }
  }

  void _promptMatchEnd(String winnerId) {
    endMatch(winnerId: winnerId, isDraw: false);
  }

  void endMatch({String? winnerId, bool isDraw = false}) async {
    final mc = Get.find<RefereeMatchController>();
    _timer?.cancel();

    Map<String, dynamic> finalScore = {
      't1_sets': team1SetsScore.toList(),
      't2_sets': team2SetsScore.toList(),
      'is_draw': isDraw,
    };

    final success = await mc.completeMatch(
      match.id,
      winnerId: winnerId,
      scoreData: finalScore
    );

    if (success) {
      Get.back(); // Retorna al dashboard
    }
  }
}
