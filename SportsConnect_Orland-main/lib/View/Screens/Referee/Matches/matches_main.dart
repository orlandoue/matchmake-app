import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Referee/Matches/referee_match_detail_screen.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/const/app_fonts.dart';
import 'package:orland_sports/controllers/referee_match_controller.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/match_model.dart';

class MatchesMain extends StatelessWidget {
  const MatchesMain({super.key});

  @override
  Widget build(BuildContext context) {
    final List<String> tabs = [
      'available'.tr,
      'scheduled'.tr,
      'recent'.tr,
    ];

    final matchController = Get.find<RefereeMatchController>();
    // Load data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      matchController.loadRefereeAvailableMatches();
      matchController.loadRefereeScheduledMatches();
      matchController.loadRefereeCompletedMatches();
    });

    return DefaultTabController(
      length: tabs.length,
      initialIndex: 0,
      child: Scaffold(
        backgroundColor: kwhite,
        appBar: simpleAppBar2(
            title: matches, haveBackButton: false, centerTitle: false),
        body: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 50,
                centerTitle: false,
                backgroundColor: kwhite,
                surfaceTintColor: kwhite,
                pinned: true,
                floating: false,
                leading: null,
                iconTheme: const IconThemeData(color: Colors.transparent),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: kwhite,
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: kgrey2.withOpacity(0.38),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TabBar(
                        automaticIndicatorColorAdjustment: false,
                        labelColor: kwhite,
                        unselectedLabelColor: kgrey1,
                        dividerColor: Colors.transparent,
                        labelStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppFonts.boston,
                            color: kwhite),
                        unselectedLabelStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: AppFonts.boston,
                            color: kgrey1),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: kpurple1,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: kpurple1.withOpacity(0.22),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        labelPadding: EdgeInsets.zero,
                        tabs: List.generate(
                          tabs.length,
                          (index) => Tab(
                            height: 44,
                            text: tabs[index],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              _AvailableMatchesTab(matchController: matchController),
              _ScheduledMatchesTab(matchController: matchController),
              _RecentMatchesTab(matchController: matchController),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab for available matches (pending acceptance)
class _AvailableMatchesTab extends StatelessWidget {
  final RefereeMatchController matchController;

  const _AvailableMatchesTab({required this.matchController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (matchController.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: kpurple1),
        );
      }

      if (matchController.refereeAvailableMatches.isEmpty) {
        return _EmptyState(
          icon: Icons.event_available,
          title: 'no_available_matches'.tr,
          subtitle: 'matches_at_courts_appear'.tr,
          onRefresh: () => matchController.loadRefereeAvailableMatches(),
        );
      }

      return RefreshIndicator(
        onRefresh: () => matchController.loadRefereeAvailableMatches(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matchController.refereeAvailableMatches.length,
          itemBuilder: (context, index) {
            final match = matchController.refereeAvailableMatches[index];
            return _RefereeMatchCard(match: match);
          },
        ),
      );
    });
  }
}

/// Tab for scheduled/confirmed matches
class _ScheduledMatchesTab extends StatelessWidget {
  final RefereeMatchController matchController;

  const _ScheduledMatchesTab({required this.matchController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (matchController.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: kpurple1),
        );
      }

      final scheduledMatches = matchController.refereeScheduledMatches;

      if (scheduledMatches.isEmpty) {
        return _EmptyState(
          icon: Icons.calendar_today,
          title: 'no_scheduled_matches'.tr,
          subtitle: 'accept_matches_hint'.tr,
          onRefresh: () => matchController.loadRefereeScheduledMatches(),
        );
      }

      return RefreshIndicator(
        onRefresh: () => matchController.loadRefereeScheduledMatches(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scheduledMatches.length,
          itemBuilder: (context, index) {
            final match = scheduledMatches[index];
            return _RefereeMatchCard(match: match);
          },
        ),
      );
    });
  }
}

/// Tab for completed matches (history)
class _RecentMatchesTab extends StatelessWidget {
  final RefereeMatchController matchController;

  const _RecentMatchesTab({required this.matchController});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (matchController.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: kpurple1),
        );
      }

      final recentMatches = matchController.refereeCompletedMatches;

      if (recentMatches.isEmpty) {
        return _EmptyState(
          icon: Icons.history,
          title: 'no_recent_matches'.tr,
          subtitle: 'completed_matches_appear'.tr,
          onRefresh: () => matchController.loadRefereeCompletedMatches(),
        );
      }

      return RefreshIndicator(
        onRefresh: () => matchController.loadRefereeCompletedMatches(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recentMatches.length,
          itemBuilder: (context, index) {
            final match = recentMatches[index];
            return _RefereeMatchCard(match: match, showWinner: true);
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

class _RefereeMatchCard extends StatelessWidget {
  final MatchModel match;
  final bool showWinner;

  const _RefereeMatchCard({
    required this.match,
    this.showWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => RefereeMatchDetailScreen(match: match)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kwhite,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: _getStatusColor(match.status).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: kgrey1.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
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
                        text: '${match.player1Name} vs ${match.player2Name}',
                        size: 15,
                        weight: FontWeight.w600,
                        color: kblack2,
                        maxLines: 1,
                        textOverflow: TextOverflow.ellipsis,
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
                    text: match.refereeDisplayStatus,
                    size: 11,
                    color: kwhite,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kgrey2.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: kgrey1),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MyText(
                          text: match.court?.name ?? 'Court',
                          size: 13,
                          color: kblack2,
                          maxLines: 1,
                          textOverflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: kgrey1),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MyText(
                          text: match.formattedDate,
                          size: 13,
                          color: kblack2,
                          weight: FontWeight.w500,
                          maxLines: 1,
                          textOverflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: kgrey1),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MyText(
                          text: match.timeRangeDisplay,
                          size: 12,
                          color: kblack2,
                          maxLines: 1,
                          textOverflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showWinner && match.winnerId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events,
                        size: 18, color: Colors.amber),
                    const SizedBox(width: 8),
                    MyText(
                      text: 'winner_name'.trParams({'name': _getWinnerName(match)}),
                      size: 13,
                      color: kblack2,
                      weight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MyText(
                  text: 'view_details'.tr,
                  size: 12,
                  color: kpurple1,
                  weight: FontWeight.w600,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: kpurple1),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getWinnerName(MatchModel match) {
    if (match.winnerId == match.player1Id) {
      return match.player1Name;
    } else if (match.winnerId == match.player2Id) {
      return match.player2Name;
    }
    return 'Unknown';
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
}
