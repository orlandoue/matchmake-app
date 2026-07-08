import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Referee/Matches/referee_match_detail_screen.dart';
import 'package:orland_sports/View/Screens/Referee/Matches/referee_score_screen.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/referee_match_controller.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/match_model.dart';

class RefereeMatchesScreen extends StatefulWidget {
  const RefereeMatchesScreen({super.key});

  @override
  State<RefereeMatchesScreen> createState() => _RefereeMatchesScreenState();
}

class _RefereeMatchesScreenState extends State<RefereeMatchesScreen> {
  late final RefereeMatchController matchController;

  @override
  void initState() {
    super.initState();
    matchController = Get.find<RefereeMatchController>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (matchController.refereeAvailableMatches.isEmpty) {
        await matchController.loadRefereeAvailableMatches();
      }

      if (matchController.refereeScheduledMatches.isEmpty) {
        await matchController.loadRefereeScheduledMatches();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kwhite,
        appBar: simpleAppBar2(
          title: 'matches'.tr,
          haveBackButton: true,
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: kgrey2.withOpacity(0.38),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
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
                splashBorderRadius: BorderRadius.circular(14),
                labelColor: kwhite,
                unselectedLabelColor: kgrey1,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                tabs: [
                  Tab(height: 44, text: 'available'.tr),
                  Tab(height: 44, text: 'scheduled'.tr),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _AvailableMatchesTab(matchController: matchController),
                  _ScheduledMatchesTab(matchController: matchController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_available, size: 64, color: kgrey1),
              const SizedBox(height: 16),
              MyText(
                text: 'no_matches_available'.tr,
                size: 16,
                color: kgrey1,
              ),
              const SizedBox(height: 8),
              MyText(
                text: 'matches_at_courts_appear'.tr,
                size: 14,
                color: kgrey1,
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => matchController.loadRefereeAvailableMatches(),
                icon: const Icon(Icons.refresh, color: kpurple1),
                label: MyText(text: 'refresh'.tr, color: kpurple1),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => matchController.loadRefereeAvailableMatches(),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: matchController.refereeAvailableMatches.length,
          itemBuilder: (context, index) {
            final match = matchController.refereeAvailableMatches[index];
            return _AvailableMatchCard(match: match);
          },
        ),
      );
    });
  }
}

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

      if (matchController.refereeScheduledMatches.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 64, color: kgrey1),
              const SizedBox(height: 16),
              MyText(
                text: 'no_scheduled_matches'.tr,
                size: 16,
                color: kgrey1,
              ),
              const SizedBox(height: 8),
              MyText(
                text: 'accept_available_matches'.tr,
                size: 14,
                color: kgrey1,
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => matchController.loadRefereeScheduledMatches(),
                icon: const Icon(Icons.refresh, color: kpurple1),
                label: MyText(text: 'refresh'.tr, color: kpurple1),
              ),
            ],
          ),
        );
      }

      // Group matches by date
      final groupedMatches =
          _groupMatchesByDate(matchController.refereeScheduledMatches);

      return RefreshIndicator(
        onRefresh: () => matchController.loadRefereeScheduledMatches(),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: groupedMatches.length,
          itemBuilder: (context, index) {
            final dateGroup = groupedMatches.keys.elementAt(index);
            final matches = groupedMatches[dateGroup]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: dateGroup,
                  size: 15,
                  weight: FontWeight.w600,
                  color: kblack2,
                  paddingBottom: 12,
                ),
                ...matches.map((match) => _ScheduledMatchCard(match: match)),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      );
    });
  }

  Map<String, List<MatchModel>> _groupMatchesByDate(List<MatchModel> matches) {
    final grouped = <String, List<MatchModel>>{};

    for (final match in matches) {
      final dateKey = match.formattedDate;
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(match);
    }

    return grouped;
  }
}

class _AvailableMatchCard extends StatelessWidget {
  final MatchModel match;

  const _AvailableMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<RefereeMatchController>();

    return GestureDetector(
      onTap: () => Get.to(() => RefereeMatchDetailScreen(match: match)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kwhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.1),
              blurRadius: 12,
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
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sports, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: '${match.player1Name} vs ${match.player2Name}',
                        size: 16,
                        weight: FontWeight.w600,
                        color: kblack2,
                        maxLines: 1,
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
                    color: Colors.orange.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: MyText(
                    text: 'pending'.tr,
                    size: 11,
                    color: Colors.orange,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                          text: match.court?.name ?? 'court'.tr,
                          size: 13,
                          color: kblack2,
                          maxLines: 1,
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
                          size: 13,
                          color: kblack2,
                          weight: FontWeight.w500,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => matchController.declineMatch(match.id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kred,
                      side: const BorderSide(color: kred),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('decline'.tr),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() {
                    final isThisLoading =
                        matchController.acceptingMatchId.value == match.id;
                    return ElevatedButton(
                      onPressed: isThisLoading
                          ? null
                          : () async {
                              await matchController.claimMatch(match.id);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kpurple1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: isThisLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: kwhite),
                            )
                          : Text('accept'.tr,
                              style: const TextStyle(color: kwhite)),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduledMatchCard extends StatelessWidget {
  final MatchModel match;

  const _ScheduledMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<RefereeMatchController>();

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
                        size: 16,
                        weight: FontWeight.w600,
                        color: kblack2,
                        maxLines: 1,
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
                const SizedBox(width: 8),
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
            const SizedBox(height: 16),
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
                          size: 13,
                          color: kblack2,
                          weight: FontWeight.w500,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (match.status == MatchStatus.confirmed ||
                match.status == MatchStatus.inProgress) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (match.status == MatchStatus.confirmed)
                    Expanded(
                      child: Obx(() => ElevatedButton(
                            onPressed: matchController.isLoading.value
                                ? null
                                : () async {
                                    await matchController.startMatch(match.id);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: matchController.isLoading.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: kwhite),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.play_arrow,
                                          color: kwhite, size: 20),
                                      const SizedBox(width: 8),
                                      Text('start_match'.tr,
                                          style: const TextStyle(color: kwhite)),
                                    ],
                                  ),
                          )),
                    ),
                  if (match.status == MatchStatus.inProgress)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Get.to(() => RefereeScoreScreen(match: match)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.scoreboard, color: kwhite, size: 20),
                            const SizedBox(width: 8),
                            Text('live_scoring'.tr,
                                style: const TextStyle(color: kwhite)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.confirmed:
        return Colors.blue;
      case MatchStatus.inProgress:
        return Colors.green;
      case MatchStatus.completed:
        return kpurple1;
      default:
        return kgrey1;
    }
  }

  IconData _getStatusIcon(MatchStatus status) {
    switch (status) {
      case MatchStatus.confirmed:
        return Icons.check_circle_outline;
      case MatchStatus.inProgress:
        return Icons.play_circle_outline;
      case MatchStatus.completed:
        return Icons.emoji_events;
      default:
        return Icons.sports;
    }
  }
}
