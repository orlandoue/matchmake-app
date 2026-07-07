import 'package:flutter/material.dart';
import 'package:orland_sports/View/BottomNavBars/bottom_nav_bar_ref.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/match_controller.dart';
import 'package:orland_sports/controllers/score_controller.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/match_model.dart';
import 'package:orland_sports/services/score_service.dart';

/// Live scoring screen for referees during an in-progress match
class RefereeScoreScreen extends StatelessWidget {
  final MatchModel match;

  const RefereeScoreScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    // Initialize score controller
    final scoreController = Get.put(ScoreController());
    scoreController.initializeMatch(match);

    final matchController = Get.find<MatchController>();

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'live_scoring'.tr,
        haveBackButton: true,
        centerTitle: false,
        actions: [
          Obx(() => scoreController.isSaving.value
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: kpurple1),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
      body: Column(
        children: [
          // Score Header
          _ScoreHeader(match: match, scoreController: scoreController),

          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Sets History
                  Obx(() {
                    final sets = scoreController.sets;
                    final is2v2 = match.matchType == MatchType.twoVsTwo;
                    if (sets.isNotEmpty) {
                      return _SetsHistoryBar(
                        sets: sets,
                        player1Name:
                            is2v2 ? match.team1DisplayName : match.player1Name,
                        player2Name:
                            is2v2 ? match.team2DisplayName : match.player2Name,
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  const SizedBox(height: 16),

                  // Current Set Info
                  Obx(() => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: kpurple1.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: MyText(
                                text: 'set_label'.trParams({
                                  'number': '${scoreController.currentSet}'
                                }),
                                size: 14,
                                color: kpurple1,
                                weight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (scoreController.servicePlayer != null)
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.sports_tennis,
                                          size: 14, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: MyText(
                                          text: 'service_label'.trParams({
                                            'name':
                                                scoreController.servicePlayer ==
                                                        match.player1Id
                                                    ? (match.matchType ==
                                                            MatchType.twoVsTwo
                                                        ? match.team1DisplayName
                                                        : match.player1Name)
                                                    : (match.matchType ==
                                                            MatchType.twoVsTwo
                                                        ? match.team2DisplayName
                                                        : match.player2Name)
                                          }),
                                          size: 12,
                                          color: Colors.green,
                                          weight: FontWeight.w500,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )),

                  const SizedBox(height: 20),

                  // Player Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Player 1 / Team 1 Actions
                        Expanded(
                          child: _PlayerScoreActions(
                            playerName: match.matchType == MatchType.twoVsTwo
                                ? match.team1DisplayName
                                : match.player1Name,
                            playerId: match.player1Id,
                            scoreController: scoreController,
                            isPlayer1: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Player 2 / Team 2 Actions
                        Expanded(
                          child: _PlayerScoreActions(
                            playerName: match.matchType == MatchType.twoVsTwo
                                ? match.team2DisplayName
                                : match.player2Name,
                            playerId: match.player2Id ?? '',
                            scoreController: scoreController,
                            isPlayer1: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Actions (fixed at bottom)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Obx(() {
                    final is2v2 = match.matchType == MatchType.twoVsTwo;
                    final servingId = scoreController.servicePlayer;
                    String? servingName;
                    if (servingId == match.player1Id) {
                      servingName =
                          is2v2 ? match.team1DisplayName : match.player1Name;
                    } else if (servingId == match.player2Id) {
                      servingName =
                          is2v2 ? match.team2DisplayName : match.player2Name;
                    }
                    return Tooltip(
                      message: servingName != null
                          ? 'Currently serving: $servingName. Tap to switch.'
                          : 'Tap to set the first server',
                      child: OutlinedButton.icon(
                        onPressed: () => scoreController.toggleServicePlayer(),
                        icon: const Icon(Icons.swap_horiz, color: kpurple1),
                        label: MyText(
                            text: servingName != null
                                ? 'server_label'.trParams({'name': servingName})
                                : 'set_server'.tr,
                            color: kpurple1,
                            weight: FontWeight.w600,
                            maxLines: 1),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kpurple1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: MyButton(
                      onTap: () =>
                          _showCompleteMatchDialog(context, matchController),
                      buttonText: 'end_match'.tr,
                      fillColor: kred,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCompleteMatchDialog(
      BuildContext context, MatchController matchController) {
    final selectedWinnerId = ''.obs;
    final scoreController = Get.find<ScoreController>();
    final is2v2 = match.matchType == MatchType.twoVsTwo;

    Get.dialog(
      AlertDialog(
        backgroundColor: kwhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            const Icon(Icons.emoji_events, size: 48, color: kpurple1),
            const SizedBox(height: 12),
            MyText(
              text: 'end_match'.tr,
              size: 20,
              weight: FontWeight.bold,
              color: kblack2,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyText(
              text: is2v2 ? 'select_winning_team'.tr : 'select_winner'.tr,
              size: 14,
              color: kgrey1,
              paddingBottom: 20,
            ),
            if (is2v2) ...[
              Obx(() => _WinnerOption(
                    name: match.team1DisplayName,
                    isSelected: selectedWinnerId.value == match.player1Id,
                    onTap: () => selectedWinnerId.value = match.player1Id,
                  )),
              const SizedBox(height: 12),
              if (match.player3Id != null)
                Obx(() => _WinnerOption(
                      name: match.team2DisplayName,
                      isSelected: selectedWinnerId.value == match.player3Id,
                      onTap: () => selectedWinnerId.value = match.player3Id!,
                    )),
            ] else ...[
              Obx(() => _WinnerOption(
                    name: match.player1Name,
                    isSelected: selectedWinnerId.value == match.player1Id,
                    onTap: () => selectedWinnerId.value = match.player1Id,
                  )),
              const SizedBox(height: 12),
              if (match.player2Id != null)
                Obx(() => _WinnerOption(
                      name: match.player2Name,
                      isSelected: selectedWinnerId.value == match.player2Id,
                      onTap: () => selectedWinnerId.value = match.player2Id!,
                    )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child: MyText(text: 'cancel'.tr, color: kgrey1),
          ),
          Obx(() => ElevatedButton(
                onPressed: selectedWinnerId.value.isEmpty ||
                        matchController.isLoading.value
                    ? null
                    : () async {
                        // Avoid UI freezing by instantly triggering the loading spinner
                        matchController.isLoading.value = true;
                        
                        try {
                          // Finalize score data to capture current set
                          final finalizedScore = ScoreService.instance
                              .finalizeScoreData(scoreController.scoreDataMap);
                          final bool success = await matchController.completeMatch(
                            match.id,
                            winnerId: selectedWinnerId.value,
                            scoreData: finalizedScore,
                          );
                          if (success) {
                            Get.offAll(() => BottomNavBarReferre()); // Go back to main panel cleanly
                          }
                        } catch (e) {
                           matchController.isLoading.value = false;
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kpurple1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: matchController.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: kwhite),
                      )
                    : MyText(text: 'confirm_winner'.tr, color: kwhite),
              )),
        ],
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final MatchModel match;
  final ScoreController scoreController;

  const _ScoreHeader({
    required this.match,
    required this.scoreController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kpurple1, Color(0xFF6B4FA0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Obx(() {
        final is2v2 = match.matchType == MatchType.twoVsTwo;
        final side1Name = is2v2 ? match.team1DisplayName : match.player1Name;
        final side2Name = is2v2 ? match.team2DisplayName : match.player2Name;

        return Row(
          children: [
            // Player 1 / Team 1
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: kwhite.withOpacity(0.2),
                    child: Icon(is2v2 ? Icons.group : Icons.person,
                        color: kwhite, size: 28),
                  ),
                  const SizedBox(height: 8),
                  MyText(
                    text: side1Name,
                    size: is2v2 ? 12 : 14,
                    color: kwhite,
                    weight: FontWeight.w600,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  // Points
                  MyText(
                    text: '${scoreController.player1Points}',
                    size: 32,
                    color: kwhite,
                    weight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MiniStat(
                        label: 'games'.tr,
                        value: '${scoreController.player1GamesWon}',
                      ),
                      const SizedBox(width: 10),
                      _MiniStat(
                        label: 'sets'.tr,
                        value: '${scoreController.player1SetsWon}',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // VS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: kwhite.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: MyText(
                text: 'vs'.tr,
                size: 18,
                color: kwhite,
                weight: FontWeight.bold,
              ),
            ),

            // Player 2 / Team 2
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: kwhite.withOpacity(0.2),
                    child: Icon(is2v2 ? Icons.group : Icons.person,
                        color: kwhite, size: 28),
                  ),
                  const SizedBox(height: 8),
                  MyText(
                    text: side2Name,
                    size: is2v2 ? 12 : 14,
                    color: kwhite,
                    weight: FontWeight.w600,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  MyText(
                    text: '${scoreController.player2Points}',
                    size: 32,
                    color: kwhite,
                    weight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MiniStat(
                        label: 'games'.tr,
                        value: '${scoreController.player2GamesWon}',
                      ),
                      const SizedBox(width: 10),
                      _MiniStat(
                        label: 'sets'.tr,
                        value: '${scoreController.player2SetsWon}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MyText(
          text: value,
          size: 16,
          color: kwhite,
          weight: FontWeight.bold,
        ),
        MyText(
          text: label,
          size: 10,
          color: kwhite.withOpacity(0.7),
        ),
      ],
    );
  }
}

class _SetsHistoryBar extends StatelessWidget {
  final List<dynamic> sets;
  final String player1Name;
  final String player2Name;

  const _SetsHistoryBar({
    required this.sets,
    required this.player1Name,
    required this.player2Name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kgrey2.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed player names column
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Matches the header row height
                const SizedBox(height: 18),
                const SizedBox(height: 6),
                MyText(
                  text: player1Name,
                  size: 13,
                  color: kblack2,
                  weight: FontWeight.w600,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                MyText(
                  text: player2Name,
                  size: 13,
                  color: kblack2,
                  weight: FontWeight.w600,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          // Horizontally scrollable sets columns
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: List.generate(sets.length, (i) {
                      return SizedBox(
                        width: 44,
                        child: Center(
                          child: MyText(
                            text: 'S${i + 1}',
                            size: 12,
                            color: kgrey1,
                            weight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  // Player 1 scores
                  Row(
                    children: List.generate(sets.length, (i) {
                      final set = sets[i] as Map<String, dynamic>;
                      return SizedBox(
                        width: 44,
                        child: Center(
                          child: MyText(
                            text: '${set['player1_games']}',
                            size: 14,
                            color: kblack2,
                            weight: FontWeight.bold,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  // Player 2 scores
                  Row(
                    children: List.generate(sets.length, (i) {
                      final set = sets[i] as Map<String, dynamic>;
                      return SizedBox(
                        width: 44,
                        child: Center(
                          child: MyText(
                            text: '${set['player2_games']}',
                            size: 14,
                            color: kblack2,
                            weight: FontWeight.bold,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerScoreActions extends StatelessWidget {
  final String playerName;
  final String playerId;
  final ScoreController scoreController;
  final bool isPlayer1;

  const _PlayerScoreActions({
    required this.playerName,
    required this.playerId,
    required this.scoreController,
    required this.isPlayer1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Player name header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isPlayer1 ? kpurple1 : const Color(0xFF4A90D9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: MyText(
              text: playerName,
              size: 14,
              color: kwhite,
              weight: FontWeight.w600,
              maxLines: 1,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'add_point'.tr,
                icon: Icons.add_circle_outline,
                color: Colors.green,
                onTap: () => scoreController.addPointForPlayer(playerId),
              ),
            ),
            const SizedBox(width: 8),
            _SubtractButton(
              onTap: () => scoreController.subtractPointForPlayer(playerId),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'game_won'.tr,
                icon: Icons.sports_score,
                color: Colors.blue,
                onTap: () => scoreController.addGameForPlayer(playerId),
              ),
            ),
            const SizedBox(width: 8),
            _SubtractButton(
              onTap: () => scoreController.subtractGameForPlayer(playerId),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'set_won'.tr,
                icon: Icons.emoji_events,
                color: Colors.orange,
                onTap: () => scoreController.addSetForPlayer(playerId),
              ),
            ),
            const SizedBox(width: 8),
            _SubtractButton(
              onTap: () => scoreController.subtractSetForPlayer(playerId),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          final fouls = isPlayer1
              ? scoreController.player1Fouls
              : scoreController.player2Fouls;
          return Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'foul_count'.trParams({'count': '$fouls'}),
                  icon: Icons.warning_amber_rounded,
                  color: kred,
                  onTap: () => scoreController.addFoulForPlayer(playerId),
                ),
              ),
              const SizedBox(width: 8),
              _SubtractButton(
                onTap: () => scoreController.subtractFoulForPlayer(playerId),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _SubtractButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SubtractButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: kred.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kred.withOpacity(0.3)),
        ),
        child: const Center(
          child: Icon(Icons.remove, size: 20, color: kred),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: MyText(
                    text: label,
                    size: 13,
                    color: color,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WinnerOption extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _WinnerOption({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? kpurple1.withOpacity(0.1) : kwhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kpurple1 : kgrey2,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: isSelected ? kpurple1 : kgrey2,
              child: Icon(
                Icons.person,
                color: isSelected ? kwhite : kgrey1,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: MyText(
                text: name,
                size: 16,
                weight: FontWeight.w600,
                color: isSelected ? kpurple1 : kblack2,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: kpurple1, size: 26),
          ],
        ),
      ),
    );
  }
}
