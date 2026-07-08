import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/History/BestRankingCategory.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/ProgressIndicator.dart';
import 'package:orland_sports/View/Widgets/RankingCard.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/player_matches_controller.dart';
import 'package:orland_sports/controllers/profile_controller.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/generated/assets.dart';

class Ranking extends StatelessWidget {
  const Ranking({super.key});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<PlayerMatchesController>();
    final profileController = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: ranking,
        haveBackButton: true,
        centerTitle: false,
      ),
      body: Obx(() {
        final currentUserId = matchController.currentUserId;
        final completedMatches = matchController.playerMatches
            .where((m) => m.status == MatchStatus.completed)
            .toList();
        final totalMatches = completedMatches.length;
        final wonMatches =
            completedMatches.where((m) => m.winnerId == currentUserId).length;
            
        final userRanking = profileController.userRankings.isNotEmpty 
            ? profileController.userRankings.first 
            : null;
            
        final String tier = userRanking?.tier ?? 'Bronce';
        final int division = userRanking?.division ?? 3; // Default Bronce 3
        final int lp = userRanking?.lp ?? 0;

        // Calculate progress based on LP (assuming 100 LP is the limit per division)
        double rankProgress = (lp / 100.0).clamp(0.0, 1.0);

        // Calculate monthly/weekly points
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final weekStart = now.subtract(Duration(days: now.weekday - 1));

        final monthlyWins = completedMatches
            .where((m) =>
                m.winnerId == currentUserId &&
                m.scheduledDate.isAfter(monthStart))
            .length;
        final weeklyWins = completedMatches
            .where((m) =>
                m.winnerId == currentUserId &&
                m.scheduledDate.isAfter(weekStart))
            .length;

        // Currently no easy way to get historical ELO out of matches history locally, 
        // falling back to wins for now but removing the 10x multiplier on the strings later.
        final monthlyPts = monthlyWins; // Switched to show raw wins instead of fake points
        final weeklyPts = weeklyWins;   // Switched to show raw wins instead of fake points

        // Get top players from completed matches
        final Map<String, Map<String, dynamic>> playerStats = {};
        for (final match in completedMatches) {
          if (match.winnerId != null) {
            final winnerId = match.winnerId!;
            if (!playerStats.containsKey(winnerId)) {
              playerStats[winnerId] = {
                'name': winnerId == match.player1Id
                    ? match.player1Name
                    : match.player2Name,
                'imageUrl': winnerId == match.player1Id
                    ? match.player1?.profileImageUrl
                    : match.player2?.profileImageUrl,
                'wins': 0,
              };
            }
            playerStats[winnerId]!['wins'] =
                (playerStats[winnerId]!['wins'] as int) + 1;
          }
        }

        final topPlayers = playerStats.entries.toList()
          ..sort((a, b) =>
              (b.value['wins'] as int).compareTo(a.value['wins'] as int));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                shrinkWrap: true,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                physics: const BouncingScrollPhysics(),
                children: [
                  RankingCard(
                    rankString: '$tier $division',
                    progress: rankProgress,
                    lp: lp,
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              MyText(
                                text: '$monthlyPts',
                                color: kblack2,
                                size: 20,
                                weight: FontWeight.bold,
                              ),
                              MyText(
                                text: monthlyPoints,
                                color: kblack2,
                                size: 14,
                                weight: FontWeight.w600,
                                paddingBottom: 6,
                              ),
                              myLinearProgressIndicator(
                                size: 120,
                                progress: totalMatches > 0
                                    ? monthlyWins / (totalMatches).clamp(1, 100)
                                    : 0.0,
                              )
                            ],
                          ),
                          CommonImageView(
                            imagePath: Assets.imagesTropy,
                            width: 39,
                            height: 53,
                          ),
                          Column(
                            children: [
                              MyText(
                                text: '$weeklyPts',
                                color: kblack2,
                                size: 20,
                                weight: FontWeight.bold,
                              ),
                              MyText(
                                text: weeklyPoints,
                                color: kblack2,
                                size: 14,
                                weight: FontWeight.w600,
                                paddingBottom: 6,
                              ),
                              myLinearProgressIndicator(
                                size: 120,
                                progress: totalMatches > 0
                                    ? weeklyWins / (totalMatches).clamp(1, 100)
                                    : 0.0,
                              )
                            ],
                          ),
                        ],
                      )),
                  SizedBox(
                    height: 35,
                  ),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyText(
                                    text: 'best_of_month'.tr,
                                    size: 18,
                                    weight: FontWeight.bold,
                                    color: kpurple1,
                                    paddingBottom: 8,
                                  ),
                                  Container(
                                    color: kpurple1,
                                    width: 150,
                                    height: 1.5,
                                  )
                                ],
                              ),
                            ),
                            Image.asset(
                              Assets.imagesFilter,
                              width: 24,
                              height: 24,
                            )
                          ])),
                  ListView.builder(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: topPlayers.length.clamp(0, 5),
                      itemBuilder: (context, index) {
                        final player = topPlayers[index];
                        return Column(
                          children: [
                            RankingCategoryCard(
                              title:
                                  player.value['name'] as String? ?? 'Player',
                              investment:
                                  '${(player.value['wins'] as int)} Victorias',
                              rankno: '${index + 1}',
                              img: player.value['imageUrl'] as String?,
                            ),
                            SizedBox(
                              height: 18,
                            ),
                          ],
                        );
                      }),
                  if (topPlayers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      child: Center(
                        child: MyText(
                          text:
                              'no_ranking_data'.tr,
                          size: 14,
                          color: kgrey1,
                          textAlign: TextAlign.center,
                        ),
                      ),
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
