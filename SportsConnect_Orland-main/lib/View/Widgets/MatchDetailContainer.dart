import 'package:flutter/material.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/generated/assets.dart';
import 'package:orland_sports/main.dart';
import 'package:orland_sports/models/match_model.dart';

class Matchdetailcontainer extends StatelessWidget {
  final bool? twoPlayer;
  final MatchModel? match;
  final String? currentUserId;
  const Matchdetailcontainer({
    super.key,
    this.twoPlayer = false,
    this.match,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final is2v2 = match?.matchType == MatchType.twoVsTwo;
    final isPlayer1 = match != null && match!.player1Id == currentUserId;
    final myName = isPlayer1
        ? (match?.player1?.name ?? you)
        : (match?.player2?.name ?? you);
    final opponentName = isPlayer1
        ? (match?.player2?.name ?? 'Waiting...')
        : (match?.player1?.name ?? 'Opponent');
    final myImage = isPlayer1
        ? match?.player1?.profileImageUrl
        : match?.player2?.profileImageUrl;
    final opponentImage = isPlayer1
        ? match?.player2?.profileImageUrl
        : match?.player1?.profileImageUrl;

    // 2v2 teammate and opponents
    final teammateName = is2v2
        ? (isPlayer1
            ? (match?.player2?.name ?? 'Waiting...')
            : (match?.player1?.name ?? 'Teammate'))
        : null;
    final teammateImage = is2v2
        ? (isPlayer1
            ? match?.player2?.profileImageUrl
            : match?.player1?.profileImageUrl)
        : null;
    final opponent2Name = is2v2 ? (match?.player4?.name ?? 'Waiting...') : null;
    final opponent2Image = is2v2 ? match?.player4?.profileImageUrl : null;
    final opponent1Name =
        is2v2 ? (match?.player3?.name ?? 'Waiting...') : opponentName;
    final opponent1Image =
        is2v2 ? match?.player3?.profileImageUrl : opponentImage;

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), color: kpurple1),
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  CommonImageView(
                    width: 55,
                    height: 50,
                    url: myImage ?? dummyImage,
                    radius: 10,
                  ),
                  MyText(
                    text: myName,
                    color: kwhite,
                    paddingTop: 4,
                    size: 14,
                    isEllipsized: true,
                  )
                ],
              ),
              if (is2v2) ...[
                SizedBox(
                  width: 35,
                ),
                Column(
                  children: [
                    CommonImageView(
                      width: 55,
                      height: 50,
                      url: teammateImage ?? dummyImage,
                      radius: 10,
                    ),
                    MyText(
                      text: teammateName ?? 'Waiting...',
                      color: kwhite,
                      paddingTop: 4,
                      size: 14,
                      isEllipsized: true,
                    )
                  ],
                ),
              ]
            ],
          ),
          SizedBox(
            height: 15,
          ),
          Stack(
            children: [
              Image.asset(
                Assets.imagesQuickplay,
                width: 150,
                height: 150,
                color: kgrey2,
              ),
              // Positioned(
              //     top: 40,
              //     left: 35,
              //     child: Column(
              //       children: [
              //         MyText(
              //           text: 'In 2hr 30min',
              //           color: kwhite,
              //           size: 15,
              //           weight: FontWeight.w500,
              //         ),
              //         SizedBox(height: 10,),
              Positioned(
                left: 0,
                right: 0,
                child: Center(
                  child: MyText(
                    text: vs,
                    color: kwhite,
                    paddingTop: 55,
                    size: 18,
                    weight: FontWeight.bold,
                  ),
                ),
              ),
              //         SizedBox(height: 10,),
              //         MyText(
              //           text: 'In 2hr 30min',
              //           color: kwhite,
              //           size: 15,
              //           weight: FontWeight.w500,
              //         ),
              //       ],
              //     ))
            ],
          ),
          SizedBox(
            height: 15,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  CommonImageView(
                    width: 55,
                    height: 50,
                    url: is2v2 ? opponent1Image : opponentImage,
                    imagePath: (is2v2 ? opponent1Image : opponentImage) == null
                        ? Assets.imagesEmpty
                        : null,
                    radius: 10,
                  ),
                  MyText(
                    text:
                        is2v2 ? (opponent1Name ?? 'Waiting...') : opponentName,
                    color: kwhite,
                    paddingTop: 4,
                    size: 14,
                    isEllipsized: true,
                  )
                ],
              ),
              if (is2v2) ...[
                SizedBox(
                  width: 35,
                ),
                Column(
                  children: [
                    CommonImageView(
                      width: 55,
                      height: 50,
                      url: opponent2Image,
                      imagePath:
                          opponent2Image == null ? Assets.imagesEmpty : null,
                      radius: 10,
                    ),
                    MyText(
                      text: opponent2Name ?? 'Waiting...',
                      color: kwhite,
                      paddingTop: 4,
                      size: 14,
                      isEllipsized: true,
                    )
                  ],
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
