import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/player_match_detail_screen.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/match_controller.dart';
import 'package:orland_sports/controllers/profile_controller.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/match_model.dart';

enum HistoryFilterType { points, totalMatches, won, lost }

class HistoryMatchesScreen extends StatelessWidget {
  final HistoryFilterType filterType;

  const HistoryMatchesScreen({super.key, required this.filterType});

  String get _title {
    switch (filterType) {
      case HistoryFilterType.points:
        return 'my_points'.tr;
      case HistoryFilterType.totalMatches:
        return 'total_matches'.tr;
      case HistoryFilterType.won:
        return 'won_matches'.tr;
      case HistoryFilterType.lost:
        return 'lost_matches'.tr;
    }
  }

  List<MatchModel> _getFilteredMatches(MatchController controller) {
    switch (filterType) {
      case HistoryFilterType.points:
      case HistoryFilterType.won:
        return controller.wonMatches;
      case HistoryFilterType.totalMatches:
        return controller.completedMatches;
      case HistoryFilterType.lost:
        return controller.lostMatches;
    }
  }

  String _getSummaryText(MatchController controller) {
    switch (filterType) {
      case HistoryFilterType.points:
        final profileController = Get.find<ProfileController>();
        // Refresh to make sure we have the latest data
        final userRanking = profileController.userRankings.isNotEmpty
            ? profileController.userRankings.first
            : null;
        final String tier     = userRanking?.tier     ?? 'Bronce';
        final int    division = userRanking?.division ?? 3; // Default Bronce 3, not 1
        final int    lp       = userRanking?.lp       ?? 0;
        final String sport    = userRanking != null ? ' · ${userRanking.sportName}' : '';
        return '$tier $division - $lp LP$sport';
      case HistoryFilterType.totalMatches:
        return '${controller.completedMatches.length} matches played';
      case HistoryFilterType.won:
        return '${controller.wonMatches.length} matches won';
      case HistoryFilterType.lost:
        return '${controller.lostMatches.length} matches lost';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MatchController>();

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: _title,
        haveBackButton: true,
        centerTitle: false,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: kpurple1),
          );
        }

        final matches = _getFilteredMatches(controller);

        return RefreshIndicator(
          onRefresh: () => controller.loadPlayerMatches(),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getSummaryColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(_getSummaryIcon(), size: 32, color: kpurple1),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MyText(
                          text: _title,
                          weight: FontWeight.bold,
                          size: 18,
                          color: kblack2,
                        ),
                        const SizedBox(height: 4),
                        MyText(
                          text: _getSummaryText(controller),
                          size: 14,
                          color: kgrey1,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              MyText(
                text: 'match_history'.tr,
                color: kblack2,
                size: 16,
                weight: FontWeight.bold,
                paddingBottom: 12,
              ),
              if (matches.isEmpty)
                _buildEmptyState()
              else
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    return _HistoryMatchTile(
                      match: matches[index],
                      currentUserId: controller.currentUserId,
                    );
                  },
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.history, size: 64, color: kgrey1),
            const SizedBox(height: 16),
            MyText(text: 'no_matches_found'.tr, size: 16, color: kgrey1),
            const SizedBox(height: 8),
            MyText(
              text: 'completed_matches_here'.tr,
              size: 14,
              color: kgrey1,
            ),
          ],
        ),
      ),
    );
  }

  Color _getSummaryColor() {
    switch (filterType) {
      case HistoryFilterType.points:
        return kpurple4;
      case HistoryFilterType.totalMatches:
        return kpurple3;
      case HistoryFilterType.won:
        return kblue;
      case HistoryFilterType.lost:
        return kpink;
    }
  }

  IconData _getSummaryIcon() {
    switch (filterType) {
      case HistoryFilterType.points:
        return Icons.stars_rounded;
      case HistoryFilterType.totalMatches:
        return Icons.sports_tennis;
      case HistoryFilterType.won:
        return Icons.emoji_events;
      case HistoryFilterType.lost:
        return Icons.trending_down;
    }
  }
}

class _HistoryMatchTile extends StatelessWidget {
  final MatchModel match;
  final String? currentUserId;

  const _HistoryMatchTile({
    required this.match,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isWinner = match.winnerId == currentUserId;
    final isCancelled = match.status == MatchStatus.cancelled;

    return GestureDetector(
      onTap: () => Get.to(() => PlayerMatchDetailScreen(match: match)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kwhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCancelled
                ? kgrey2
                : (isWinner
                    ? kpurple1.withOpacity(0.3)
                    : kred.withOpacity(0.3)),
          ),
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
                    color: isCancelled
                        ? kgrey2
                        : (isWinner
                            ? kpurple1.withOpacity(0.1)
                            : kred.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCancelled
                        ? Icons.cancel_outlined
                        : (isWinner ? Icons.emoji_events : Icons.sports_tennis),
                    color: isCancelled ? kgrey1 : (isWinner ? kpurple1 : kred),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: '${match.player1Name} vs ${match.player2Name}',
                        size: 15,
                        weight: FontWeight.w600,
                        color: kblack2,
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCancelled ? kgrey2 : (isWinner ? kpurple1 : kred),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: MyText(
                    text:
                        isCancelled ? 'cancelled'.tr : (isWinner ? 'won'.tr : 'lost'.tr),
                    size: 12,
                    color: isCancelled ? kgrey1 : kwhite,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: kgrey1),
                const SizedBox(width: 4),
                Expanded(
                  child: MyText(
                    text: match.court?.name ?? 'Court',
                    size: 12,
                    color: kgrey1,
                    maxLines: 1,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 14, color: kgrey1),
                const SizedBox(width: 4),
                MyText(
                  text: match.formattedDate,
                  size: 12,
                  color: kgrey1,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
