import 'package:flutter/material.dart';
import 'package:orland_sports/View/BottomNavBars/bottom_nav_bar_ref.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Referee/Matches/referee_check_in_screen.dart';
import 'package:orland_sports/View/Screens/Referee/Matches/referee_score_screen.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/referee_match_controller.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/match_model.dart';
import 'package:orland_sports/services/score_service.dart';

/// Detailed view of a match for referees
class RefereeMatchDetailScreen extends StatelessWidget {
  final MatchModel match;

  const RefereeMatchDetailScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<RefereeMatchController>();

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'match_details'.tr,
        haveBackButton: true,
        centerTitle: false,
      ),
      body: Obx(() {
        // Get the latest match data from controller if available
        final currentMatch = matchController.refereeScheduledMatches
                .firstWhereOrNull((m) => m.id == match.id) ??
            matchController.refereeAvailableMatches
                .firstWhereOrNull((m) => m.id == match.id) ??
            match;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Header with Countdown
              _StatusHeader(match: currentMatch),

              const SizedBox(height: 24),

              // Players Section
              _PlayersSection(match: currentMatch),

              const SizedBox(height: 24),

              // Match Info Section
              _MatchInfoSection(match: currentMatch),

              const SizedBox(height: 24),

              // Court Section
              if (currentMatch.court != null)
                _CourtSection(match: currentMatch),

              const SizedBox(height: 32),

              // Action Buttons based on status
              _ActionButtons(
                  match: currentMatch, matchController: matchController),
            ],
          ),
        );
      }),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final MatchModel match;

  const _StatusHeader({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(match.status).withOpacity(0.15),
            _getStatusColor(match.status).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(match.status).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            _getStatusIcon(match.status),
            size: 56,
            color: _getStatusColor(match.status),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _getStatusColor(match.status),
              borderRadius: BorderRadius.circular(25),
            ),
            child: MyText(
              text: match.refereeDisplayStatus,
              size: 16,
              color: kwhite,
              weight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          MyText(
            text: '${match.formattedDate} at ${match.timeRangeDisplay}',
            size: 14,
            color: kblack2,
            weight: FontWeight.w600,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.matched:
        return Colors.orange;
      case MatchStatus.confirmed:
        return Colors.blue;
      case MatchStatus.inProgress:
        return Colors.green;
      case MatchStatus.completed:
        return kpurple1;
      case MatchStatus.cancelled:
        return kred;
      default:
        return kgrey1;
    }
  }

  IconData _getStatusIcon(MatchStatus status) {
    switch (status) {
      case MatchStatus.matched:
        return Icons.hourglass_empty;
      case MatchStatus.confirmed:
        return Icons.check_circle;
      case MatchStatus.inProgress:
        return Icons.play_circle_filled;
      case MatchStatus.completed:
        return Icons.emoji_events;
      case MatchStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.sports_tennis;
    }
  }
}

class _PlayersSection extends StatelessWidget {
  final MatchModel match;

  const _PlayersSection({required this.match});

  @override
  Widget build(BuildContext context) {
    final is2v2 = match.matchType == MatchType.twoVsTwo;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kwhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kgrey2),
        boxShadow: [
          BoxShadow(
            color: kgrey1.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            text: match.matchType.displayName,
            size: 14,
            color: kpurple1,
            weight: FontWeight.w600,
            paddingBottom: 16,
          ),
          if (is2v2) ...[
            // Team 1
            MyText(
              text: 'team_1'.tr,
              size: 13,
              weight: FontWeight.w600,
              color: kpurple1,
              paddingBottom: 8,
            ),
            Row(
              children: [
                Expanded(
                    child: _PlayerCard(
                        name: match.player1Name, label: 'player_1'.tr, isCheckedIn: match.player1CheckedIn)),
                const SizedBox(width: 8),
                Expanded(
                    child: _PlayerCard(
                        name: match.player2Id != null
                            ? (match.player2?.name ?? 'Player 2')
                            : 'waiting_dots'.tr,
                        label: 'player_2'.tr,
                        isCheckedIn: match.player2Id != null ? match.player2CheckedIn : null)),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: kpurple1,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: MyText(
                  text: 'vs'.tr,
                  size: 16,
                  color: kwhite,
                  weight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Team 2
            MyText(
              text: 'team_2'.tr,
              size: 13,
              weight: FontWeight.w600,
              color: Colors.blue,
              paddingBottom: 8,
            ),
            Row(
              children: [
                Expanded(
                    child: _PlayerCard(
                        name: match.player3Id != null
                            ? (match.player3?.name ?? 'Player 3')
                            : 'waiting_dots'.tr,
                        label: 'player_3'.tr,
                        isCheckedIn: match.player3Id != null ? match.player3CheckedIn : null)),
                const SizedBox(width: 8),
                Expanded(
                    child: _PlayerCard(
                        name: match.player4Id != null
                            ? (match.player4?.name ?? 'Player 4')
                            : 'waiting_dots'.tr,
                        label: 'player_4'.tr,
                        isCheckedIn: match.player4Id != null ? match.player4CheckedIn : null)),
              ],
            ),
          ] else ...[
            // 1v1 layout
            Row(
              children: [
                Expanded(
                    child: _PlayerCard(
                        name: match.player1Name, label: 'player_1'.tr, isCheckedIn: match.player1CheckedIn)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: kpurple1,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: MyText(
                    text: 'vs'.tr,
                    size: 16,
                    color: kwhite,
                    weight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: _PlayerCard(
                    name: match.player2Name ?? 'waiting_dots'.tr,
                    label: 'player_2'.tr,
                    isCheckedIn: match.player2Id != null ? match.player2CheckedIn : null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String name;
  final String label;
  final bool? isCheckedIn;

  const _PlayerCard({required this.name, required this.label, this.isCheckedIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kgrey2.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: kpurple1.withOpacity(0.1),
            child: const Icon(Icons.person, color: kpurple1, size: 32),
          ),
          const SizedBox(height: 10),
          MyText(
            text: name,
            size: 14,
            weight: FontWeight.w600,
            color: kblack2,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          MyText(
            text: label,
            size: 11,
            color: kgrey1,
          ),
          if (isCheckedIn != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCheckedIn! ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isCheckedIn! ? Icons.check_circle : Icons.pending_actions,
                    size: 12,
                    color: isCheckedIn! ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  MyText(
                    text: isCheckedIn! ? 'Listo' : 'Pendiente',
                    size: 10,
                    color: isCheckedIn! ? Colors.green : Colors.orange,
                    weight: FontWeight.bold,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchInfoSection extends StatelessWidget {
  final MatchModel match;

  const _MatchInfoSection({required this.match});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kwhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kgrey2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            text: 'match_information'.tr,
            size: 16,
            weight: FontWeight.bold,
            color: kblack2,
            paddingBottom: 16,
          ),
          _InfoRow(
              icon: Icons.sports_tennis,
              label: 'type'.tr,
              value: match.matchType.displayName),
          _InfoRow(
              icon: Icons.calendar_today,
              label: 'date'.tr,
              value: match.formattedDate),
          _InfoRow(
              icon: Icons.access_time,
              label: 'time'.tr,
              value: match.timeRangeDisplay),
          _InfoRow(
              icon: Icons.shuffle,
              label: 'mode'.tr,
              value: match.matchMode.displayName),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kgrey2.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: kgrey1),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: MyText(text: label, size: 14, color: kgrey1, isEllipsized: true),
          ),
          const Spacer(),
          Flexible(
            flex: 3,
            child: MyText(
              text: value,
              size: 14,
              color: kblack2,
              weight: FontWeight.w600,
              textAlign: TextAlign.right,
              isEllipsized: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourtSection extends StatelessWidget {
  final MatchModel match;

  const _CourtSection({required this.match});

  @override
  Widget build(BuildContext context) {
    final court = match.court!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kwhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kgrey2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            text: 'court'.tr,
            size: 16,
            weight: FontWeight.bold,
            color: kblack2,
            paddingBottom: 16,
          ),
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: kpurple1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.sports_tennis, color: kpurple1, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MyText(
                      text: court.name,
                      size: 16,
                      weight: FontWeight.w600,
                      color: kblack2,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          court.isIndoor ? Icons.home : Icons.wb_sunny,
                          size: 14,
                          color: kgrey1,
                        ),
                        const SizedBox(width: 4),
                        MyText(
                          text: court.isIndoor
                              ? 'indoor_court'.tr
                              : 'outdoor_court'.tr,
                          size: 13,
                          color: kgrey1,
                        ),
                      ],
                    ),
                    if (court.address != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: kgrey1),
                          const SizedBox(width: 4),
                          Expanded(
                            child: MyText(
                              text: court.address!,
                              size: 12,
                              color: kgrey1,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final MatchModel match;
  final RefereeMatchController matchController;

  const _ActionButtons({
    required this.match,
    required this.matchController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = matchController.isLoading.value;

      // For matches pending referee confirmation
      if (match.status == MatchStatus.matched) {
        return Column(
          children: [
            MyButton(
              onTap: isLoading
                  ? () {}
                  : () async {
                      await matchController.claimMatch(match.id);
                    },
              buttonText: isLoading ? 'processing'.tr : 'accept_match'.tr,
              fillColor: kpurple1,
            ),
            const SizedBox(height: 12),
            MyButton(
              onTap: isLoading
                  ? () {}
                  : () => matchController.declineMatch(match.id),
              buttonText: 'decline'.tr,
              fillColor: kwhite,
              outlineColor: kred,
              fontColor: kred,
            ),
          ],
        );
      }

      // For confirmed matches - Check-in and start
      if (match.status == MatchStatus.confirmed) {
        final allCheckedIn = match.areAllPlayersCheckedIn;

        return Column(
          children: [
            // Check-in button always available if not both checked in
            if (!allCheckedIn) ...[
              MyButton(
                onTap: () =>
                    Get.to(() => RefereeCheckInScreen(matchId: match.id)),
                buttonText: 'Iniciar Check-in QR',
                fillColor: kpurple1,
              ),
              const SizedBox(height: 12),
            ],

            // Start Match button only if all are checked in
            MyButton(
              onTap: isLoading || !allCheckedIn
                  ? () {}
                  : () async {
                      await matchController.startMatch(match.id);
                    },
              buttonText: isLoading
                  ? 'Iniciando...'
                  : (allCheckedIn 
                      ? 'Iniciar Partido' 
                      : 'Esperando Check-in (${match.checkedInCount}/${match.totalSlots})'),
              fillColor: allCheckedIn ? Colors.green : kgrey1,
            ),
          ],
        );
      }

      // For in-progress matches - can score and complete
      if (match.status == MatchStatus.inProgress) {
        return Column(
          children: [
            MyButton(
              onTap: () => Get.to(() => RefereeScoreScreen(match: match)),
              buttonText: 'open_live_scoring'.tr,
              fillColor: Colors.green,
            ),
            const SizedBox(height: 12),
            MyButton(
              onTap: () => _showCompleteMatchDialog(context),
              buttonText: 'complete_match'.tr,
              fillColor: kpurple1,
            ),
          ],
        );
      }

      // For finished matches
      if (match.status == MatchStatus.completed) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kpurple1.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Icon(Icons.emoji_events, size: 56, color: kpurple1),
              const SizedBox(height: 16),
              MyText(
                text: 'match_completed_excl'.tr,
                size: 20,
                weight: FontWeight.bold,
                color: kblack2,
              ),
              if (match.winnerId != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: MyText(
                    text: '🏆 Winner: ${match.winnerDisplayName}',
                    size: 14,
                    color: kblack2,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
              if (match.scoreData != null && match.scoreData!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _CompletedScoreSummary(match: match),
              ],
            ],
          ),
        );
      }

      return const SizedBox.shrink();
    });
  }

  void _showCompleteMatchDialog(BuildContext context) {
    final selectedWinnerId = ''.obs;
    final is2v2 = match.matchType == MatchType.twoVsTwo;

    Get.dialog(
      AlertDialog(
        backgroundColor: kwhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            const Icon(Icons.emoji_events, size: 56, color: kpurple1),
            const SizedBox(height: 16),
            MyText(
              text: 'complete_match'.tr,
              size: 22,
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
              paddingBottom: 24,
            ),
            if (is2v2) ...[
              // Team 1 option
              Obx(() => _WinnerOption(
                    name: match.team1DisplayName,
                    isSelected: selectedWinnerId.value == match.player1Id,
                    onTap: () => selectedWinnerId.value = match.player1Id,
                  )),
              const SizedBox(height: 12),
              // Team 2 option
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
                        matchController.isLoading.value = true;
                        try {
                          // Load latest score data and finalize before completing
                          final rawScoreData =
                              await ScoreService.instance.getMatchScore(match.id);
                          final finalizedScore = rawScoreData != null
                              ? ScoreService.instance
                                  .finalizeScoreData(rawScoreData)
                              : null;
                          final success = await matchController.completeMatch(
                              match.id, winnerId: selectedWinnerId.value,
                              scoreData: finalizedScore);
                          
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

/// Widget to display score summary for completed matches
class _CompletedScoreSummary extends StatelessWidget {
  final MatchModel match;

  const _CompletedScoreSummary({required this.match});

  @override
  Widget build(BuildContext context) {
    final scoreData = match.scoreData!;
    final p1Sets = scoreData['player1_sets_won'] as int? ?? 0;
    final p2Sets = scoreData['player2_sets_won'] as int? ?? 0;
    final p1Points = scoreData['player1_points'] as int? ?? 0;
    final p2Points = scoreData['player2_points'] as int? ?? 0;
    final p1Fouls = scoreData['player1_fouls'] as int? ?? 0;
    final p2Fouls = scoreData['player2_fouls'] as int? ?? 0;
    final sets = scoreData['sets'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kgrey2.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MyText(
            text: 'score_summary'.tr,
            size: 14,
            weight: FontWeight.bold,
            color: kblack2,
            paddingBottom: 12,
          ),
          // Sets score
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MyText(
                text: match.player1Name,
                size: 13,
                color: kblack2,
                weight: FontWeight.w600,
              ),
              const Spacer(),
              MyText(
                text: '$p1Sets',
                size: 20,
                color: kpurple1,
                weight: FontWeight.bold,
              ),
              MyText(
                text: ' - ',
                size: 20,
                color: kblack2,
                weight: FontWeight.bold,
              ),
              MyText(
                text: '$p2Sets',
                size: 20,
                color: kpurple1,
                weight: FontWeight.bold,
              ),
              const Spacer(),
              MyText(
                text: match.player2Name,
                size: 13,
                color: kblack2,
                weight: FontWeight.w600,
              ),
            ],
          ),
          if (sets.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 4),
            ...sets.map((s) {
              final set = s as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MyText(
                      text: 'set_number'
                          .trParams({'number': set['set_number'].toString()}),
                      size: 12,
                      color: kgrey1,
                    ),
                    const SizedBox(width: 12),
                    MyText(
                      text: '${set['player1_games']} - ${set['player2_games']}',
                      size: 14,
                      color: kblack2,
                      weight: FontWeight.w600,
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                  label: 'points'.tr, value1: '$p1Points', value2: '$p2Points'),
              _StatChip(
                  label: 'fouls'.tr, value1: '$p1Fouls', value2: '$p2Fouls'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value1;
  final String value2;

  const _StatChip(
      {required this.label, required this.value1, required this.value2});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MyText(text: label, size: 11, color: kgrey1),
        const SizedBox(height: 4),
        MyText(
          text: '$value1 - $value2',
          size: 14,
          color: kblack2,
          weight: FontWeight.w600,
        ),
      ],
    );
  }
}
