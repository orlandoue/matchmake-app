import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Referee/Home/MatchDetails/match_details.dart';
import 'package:orland_sports/View/Screens/Users/History/History.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/ManageMatch.dart';
import 'package:orland_sports/View/Widgets/ButtonContainer.dart';
import 'package:orland_sports/View/Widgets/ExpandedRow.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';

import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';


class RefereeProfileDetail extends StatelessWidget {
  const RefereeProfileDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
          title: 'profile_details'.tr,
          haveBackButton: true,
          centerTitle: false,
          actions: [
            IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: kblack2,
                ))
          ]),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                MemberContainer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MyText(
                      text: 'rank'.tr,
                      size: 12,
                      color: kgrey1,
                      weight: FontWeight.w600,
                      paddingBottom: 6,
                    ),
                    MyText(
                      text: 'ranking'.tr,
                      size: 12,
                      color: kgrey1,
                      weight: FontWeight.w600,
                      paddingBottom: 6,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buttonContainer(
                      radius: 0,
                      text: 'gold'.tr,
                      bgColor: kpurple1,
                      textsize: 14,
                      txtColor: kwhite,
                      vPadding: 5,
                    ),
                    buttonContainer(
                      radius: 0,
                      text: 'TOP #210',
                      bgColor: kpurple1,
                      textsize: 14,
                      txtColor: kwhite,
                      vPadding: 5,
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    HistoryColoredCards(
                      title: myPoints,
                      subTitle: '240',
                      bgColor: kpurple4,
                      ontap: () {
                        // Get.to(() => WinMatches());
                      },
                    ),
                    HistoryColoredCards(
                      title: totalMatches,
                      subTitle: '240',
                      bgColor: kpurple3,
                      ontap: () {
                        // Get.to(() => WinMatches());
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    HistoryColoredCards(
                      title: win,
                      subTitle: '240',
                      bgColor: kblue,
                      ontap: () {
                        //Get.to(() => WinMatches());
                      },
                    ),
                    HistoryColoredCards(
                      title: lose,
                      subTitle: '240',
                      bgColor: kpink,
                      ontap: () {
                        // Get.to(() => LoseMatches());
                      },
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                TwoTextedColumn(
                  text1: 'player_skill'.tr,
                  text2: 'professional'.tr,
                ),
                SizedBox(
                  height: 15,
                ),
                TwoTextedColumn(
                  text1: 'favorite_position'.tr,
                  text2: 'left'.tr,
                ),
                SizedBox(
                  height: 15,
                ),
                MyText(
                  text: 'recent_matches'.tr,
                  color: kblack2,
                  size: 16,
                  weight: FontWeight.w700,
                  paddingBottom: 10,
                ),
                ListView.builder(
                    // padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: 2,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          manageMatchcard(
                            border: kgrey2,
                            bgColor: kwhite,
                            textColor: kgrey1,
                            statusColor: kgrey1,
                            Statustext: '02:00 pm',
                            weight: FontWeight.w400,
                            overallTap: () {
                              Get.to(() => ReferreMatchDetail());
                            },
                          ),
                          SizedBox(
                            height: 12,
                          ),
                        ],
                      );
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
