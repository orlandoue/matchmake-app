import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/player_match_detail_screen.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/player_matches_controller.dart';
import 'package:orland_sports/controllers/match_creation_controller.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/match_model.dart';

/// Screen to view all player's matches (active and history)
class PlayerMatchesScreen extends StatelessWidget {
  const PlayerMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<PlayerMatchesController>();

    // Ensure fresh data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      matchController.loadPlayerMatches();
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: kwhite,
        appBar: simpleAppBar2(
          title: 'my_matches'.tr,
          haveBackButton: true,
          centerTitle: false,
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: kgrey2.withOpacity(0.5),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: kpurple1,
                  borderRadius: BorderRadius.circular(25),
                ),
                labelColor: kwhite,
                unselectedLabelColor: kgrey1,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: 'active'.tr),
                  Tab(text: 'waiting'.tr),
                  Tab(text: 'completed'.tr),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ActiveMatchesTab(matchController: matchController),
                  _WaitingMatchesTab(matchController: matchController),
                  _CompletedMatchesTab(matchController: matchController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveMatchesTab extends StatelessWidget {
  final PlayerMatchesController matchController;

  const _ActiveMatchesTab({required this.matchController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (matchController.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: kpurple1),
        );
      }

      final activeMatches = matchController.playerMatches
          .where((m) =>
              m.status == MatchStatus.matched ||
              m.status == MatchStatus.confirmed ||
              m.status == MatchStatus.inProgress)
          .toList();

      if (activeMatches.isEmpty) {
        return _EmptyState(
          icon: Icons.sports_tennis,
          title: 'no_active_matches'.tr,
          subtitle: 'join_or_create_match'.tr,
          onRefresh: () => matchController.loadPlayerMatches(),
        );
      }

      return RefreshIndicator(
        onRefresh: () => matchController.loadPlayerMatches(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeMatches.length,
          itemBuilder: (context, index) {
            final match = activeMatches[index];
            return _PlayerMatchCard(match: match);
          },
        ),
      );
    });
  }
}

class _WaitingMatchesTab extends StatelessWidget {
  final PlayerMatchesController matchController;

  const _WaitingMatchesTab({required this.matchController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (matchController.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: kpurple1),
        );
      }

      final waitingMatches = matchController.playerMatches
          .where((m) => m.status == MatchStatus.waitingForOpponent)
          .toList();

      if (waitingMatches.isEmpty) {
        return _EmptyState(
          icon: Icons.hourglass_empty,
          title: 'no_waiting_matches'.tr,
          subtitle: 'create_match_wait'.tr,
          onRefresh: () => matchController.loadPlayerMatches(),
        );
      }

      return RefreshIndicator(
        onRefresh: () => matchController.loadPlayerMatches(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: waitingMatches.length,
          itemBuilder: (context, index) {
            final match = waitingMatches[index];
            return _PlayerMatchCard(match: match, showInviteCode: true);
          },
        ),
      );
    });
  }
}

class _CompletedMatchesTab extends StatelessWidget {
  final PlayerMatchesController matchController;

  const _CompletedMatchesTab({required this.matchController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (matchController.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: kpurple1),
        );
      }

      final completedMatches = matchController.playerMatches
          .where((m) =>
              m.status == MatchStatus.completed ||
              m.status == MatchStatus.cancelled)
          .toList();

      if (completedMatches.isEmpty) {
        return _EmptyState(
          icon: Icons.history,
          title: 'no_completed_matches'.tr,
          subtitle: 'match_history_appear'.tr,
          onRefresh: () => matchController.loadPlayerMatches(),
        );
      }

      return RefreshIndicator(
        onRefresh: () => matchController.loadPlayerMatches(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedMatches.length,
          itemBuilder: (context, index) {
            final match = completedMatches[index];
            return _PlayerMatchCard(match: match);
          },
        ),
      );
    });
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onRefresh;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: kgrey1),
          const SizedBox(height: 16),
          MyText(text: title, size: 16, color: kgrey1),
          const SizedBox(height: 8),
          MyText(text: subtitle, size: 14, color: kgrey1),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, color: kpurple1),
            label: MyText(text: 'refresh'.tr, color: kpurple1),
          ),
        ],
      ),
    );
  }
}

class _PlayerMatchCard extends StatelessWidget {
  final MatchModel match;
  final bool showInviteCode;

  const _PlayerMatchCard({
    required this.match,
    this.showInviteCode = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => PlayerMatchDetailScreen(match: match)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kwhite,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: _getStatusColor(match.status).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: kgrey1.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getStatusColor(match.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getStatusIcon(match.status),
                    color: _getStatusColor(match.status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: _getMatchTitle(match),
                        size: 15,
                        weight: FontWeight.w600,
                        color: kblack2,
                        isEllipsized: true,
                      ),
                      const SizedBox(height: 4),
                      MyText(
                        text: match.matchType.displayName,
                        size: 12,
                        color: kgrey1,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(match.status),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: MyText(
                    text: match.status.displayName,
                    size: 11,
                    color: kwhite,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kgrey2.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: kgrey1),
                  const SizedBox(width: 6),
                  Expanded(
                    child: MyText(
                      text: match.court?.name ?? 'court'.tr,
                      size: 13,
                      color: kblack2,
                      isEllipsized: true,
                    ),
                  ),
                  const Icon(Icons.access_time, size: 16, color: kgrey1),
                  const SizedBox(width: 4),
                  Flexible(
                    child: MyText(
                      text: '${match.formattedDate} • ${match.timeRangeDisplay}',
                      size: 11, // Slightly smaller to fit better
                      color: kblack2,
                      isEllipsized: true,
                    ),
                  ),
                ],
              ),
            ),
            if (showInviteCode &&
                match.inviteCode != null &&
                match.inviteCode!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kpurple1.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kpurple1.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.key, size: 18, color: kpurple1),
                    const SizedBox(width: 8),
                    MyText(
                      text: 'invite_code_prefix'.tr,
                      size: 13,
                      color: kgrey1,
                    ),
                    MyText(
                      text: match.inviteCode!,
                      size: 15,
                      color: kpurple1,
                      weight: FontWeight.bold,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        MatchCreationController.instance.copyInviteCode(match.inviteCode!);
                      },
                      icon: const Icon(Icons.copy, size: 20, color: kpurple1),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
            if (match.status == MatchStatus.waitingForOpponent) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelConfirmation(match),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: Text('cancel_match'.tr),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kred,
                    side: const BorderSide(color: kred),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getMatchTitle(MatchModel match) {
    if (match.player2Id != null) {
      return '${match.player1Name} vs ${match.player2Name}';
    }
    return '${match.player1Name}${'waiting_for_opponent_suffix'.tr}';
  }

  Color _getStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.waitingForOpponent:
        return Colors.orange;
      case MatchStatus.matched:
        return Colors.blue;
      case MatchStatus.confirmed:
        return Colors.teal;
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
      case MatchStatus.waitingForOpponent:
        return Icons.hourglass_empty;
      case MatchStatus.matched:
        return Icons.people;
      case MatchStatus.confirmed:
        return Icons.check_circle_outline;
      case MatchStatus.inProgress:
        return Icons.play_circle_outline;
      case MatchStatus.completed:
        return Icons.emoji_events;
      case MatchStatus.cancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.sports_tennis;
    }
  }

  void _showCancelConfirmation(MatchModel match) {
    final matchController = Get.find<PlayerMatchesController>();

    Get.dialog(
      AlertDialog(
        backgroundColor: kwhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: MyText(
          text: 'cancel_match_question'.tr,
          size: 20,
          weight: FontWeight.bold,
          color: kblack2,
        ),
        content: MyText(
          text: 'cancel_match_confirm'.tr,
          size: 14,
          color: kgrey1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child: MyText(text: 'no_keep_it'.tr, color: kgrey1),
          ),
          Obx(() => ElevatedButton(
                onPressed: matchController.isLoading.value
                    ? null
                    : () async {
                        await MatchCreationController.instance.cancelMatch(match.id);
                        Navigator.pop(Get.context!);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kred,
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
                    : MyText(text: 'yes_cancel'.tr, color: kwhite),
              )),
        ],
      ),
    );
  }
}
