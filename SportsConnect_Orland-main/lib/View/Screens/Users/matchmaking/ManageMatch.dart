import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Referee/Home/MatchDetails/match_details.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/cancelMatch.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/match_controller.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/main.dart';
import 'package:orland_sports/models/match_model.dart';

class ManageMatch extends StatelessWidget {
  const ManageMatch({super.key});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<MatchController>();

    // Load player matches when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      matchController.loadPlayerMatches();
    });

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
          title: manageMatch,
          haveBackButton: true,
          centerTitle: false,
          actions: [
            ticketcount(),
            SizedBox(
              width: 13,
            )
          ]),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Obx(() {
              if (matchController.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: kpurple1),
                );
              }

              final manageableMatches = matchController.playerMatches
                  .where((m) =>
                      m.status == MatchStatus.inProgress ||
                      m.status == MatchStatus.waitingForOpponent ||
                      m.status == MatchStatus.pending ||
                      m.status == MatchStatus.matched ||
                      m.status == MatchStatus.confirmed)
                  .toList();

              if (manageableMatches.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_tennis, size: 64, color: kgrey1),
                      const SizedBox(height: 16),
                      MyText(
                        text: 'no_matches_to_manage'.tr,
                        size: 16,
                        color: kgrey1,
                        weight: FontWeight.w500,
                      ),
                      const SizedBox(height: 8),
                      MyText(
                        text: 'create_or_join_match'.tr,
                        size: 14,
                        color: kgrey1,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: manageableMatches.length,
                itemBuilder: (context, index) {
                  final match = manageableMatches[index];
                  final currentUserId = matchController.currentUserId;
                  final isPlayer1 = match.player1Id == currentUserId;

                  String timeText = '';
                  final now = DateTime.now();
                  final diff = match.scheduledDate.difference(now);
                  if (diff.isNegative) {
                    timeText = 'in_progress'.tr;
                  } else if (diff.inHours > 0) {
                    timeText = 'In ${diff.inHours}hr ${diff.inMinutes % 60}min';
                  } else {
                    timeText = 'In ${diff.inMinutes}min';
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: manageMatchcard(
                      match: match,
                      currentUserId: currentUserId,
                      dateortime1: timeText.isNotEmpty ? timeText : null,
                      dateortime2: match.court?.name ?? 'Court',
                      Statustext:
                          match.status == MatchStatus.inProgress ? 'LIVE' : vs,
                      overallTap: () {
                        Get.to(() => CancelMatch(match: match));
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class manageMatchcard extends StatelessWidget {
  final Color? bgColor;
  final Color? textColor;
  final Color? statusColor;
  final Color? border;
  final String? Statustext;
  final String? dateortime1;
  final FontWeight? weight;
  final String? dateortime2;
  final MatchModel? match;
  final String? currentUserId;
  final VoidCallback? overallTap, playertap, player2Tap;
  const manageMatchcard({
    super.key,
    this.bgColor,
    this.textColor,
    this.border,
    this.Statustext,
    this.dateortime1,
    this.dateortime2,
    this.statusColor,
    this.weight,
    this.overallTap,
    this.playertap,
    this.player2Tap,
    this.match,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final is2v2 = match?.matchType == MatchType.twoVsTwo;
    // Determine player names and images from match data
    final isPlayer1 = match != null && match!.player1Id == currentUserId;

    // For 2v2, show team names; for 1v1, show individual names
    String myName;
    String opponentName;
    String? myImage;
    String? opponentImage;

    if (is2v2) {
      myName = match?.team1DisplayName ?? 'you'.tr;
      opponentName = match?.team2DisplayName ?? 'waiting_dots'.tr;
      myImage = isPlayer1
          ? match?.player1?.profileImageUrl
          : match?.player3?.profileImageUrl;
      opponentImage = isPlayer1
          ? match?.player3?.profileImageUrl
          : match?.player1?.profileImageUrl;
    } else {
      myName = isPlayer1
          ? (match?.player1?.name ?? 'you'.tr)
          : (match?.player2?.name ?? 'you'.tr);
      opponentName = isPlayer1
          ? (match?.player2?.name ?? 'waiting_dots'.tr)
          : (match?.player1?.name ?? 'opponent'.tr);
      myImage = isPlayer1
          ? match?.player1?.profileImageUrl
          : match?.player2?.profileImageUrl;
      opponentImage = isPlayer1
          ? match?.player2?.profileImageUrl
          : match?.player1?.profileImageUrl;
    }

    return GestureDetector(
      onTap: overallTap ??
          () {
            Get.to(() => CancelMatch(match: match));
          },
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(color: border ?? ktransparent),
            color: bgColor ?? kpurple1,
            borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MemberContainer(
              name: myName,
              image: myImage,
              size: 50,
              ontap: playertap,
              textColor: textColor ?? kwhite,
            ),
            Column(
              children: [
                MyText(
                  text: dateortime1 ?? '',
                  color: textColor ?? kwhite,
                  size: 15,
                  weight: FontWeight.w500,
                ),
                SizedBox(
                  height: 10,
                ),
                MyText(
                  text: Statustext ?? vs,
                  color: statusColor ?? kwhite,
                  paddingTop: 4,
                  size: 18,
                  weight: weight ?? FontWeight.bold,
                ),
                SizedBox(
                  height: 10,
                ),
                MyText(
                  text: dateortime2 ?? '',
                  color: textColor ?? kwhite,
                  size: 15,
                  weight: FontWeight.w500,
                ),
              ],
            ),
            MemberContainer(
              name: opponentName,
              image: opponentImage,
              size: 50,
              ontap: player2Tap,
              textColor: textColor ?? kwhite,
            )
          ],
        ),
      ),
    );
  }
}
