import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/ButtonContainer.dart';
import 'package:orland_sports/View/Widgets/ExpandedRow.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/main.dart';

class ProfileInfo extends StatelessWidget {
  const ProfileInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'profile_info'.tr,
        haveBackButton: true,
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                MyText(
                  text: 'ranking'.tr,
                  size: 12,
                  color: kgrey1,
                  textAlign: TextAlign.end,
                  weight: FontWeight.w600,
                  paddingBottom: 6,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                ProfileInfoCard(),
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
                  text: 'linked_team'.tr,
                  size: 14,
                  color: kblack2,
                  weight: FontWeight.bold,
                  paddingBottom: 8,
                ),
                buttonContainer(
                  borderColor: kgrey2,
                  bgColor: kwhite,
                  text: 'add_team'.tr,
                  icon: Icons.add,
                  txtColor: kgrey1,
                  iconColor: kgrey1,
                  iscenter: false,
                  radius: 6,
                  vPadding: 12,
                  onTap: () {},
                ),
                SizedBox(
                  height: 12,
                ),
                buttonContainer(
                  borderColor: kgrey2,
                  bgColor: kwhite,
                  text: 'add_team'.tr,
                  icon: Icons.add,
                  txtColor: kgrey1,
                  iconColor: kgrey1,
                  iscenter: false,
                  radius: 6,
                  vPadding: 12,
                  onTap: () {},
                ),
                SizedBox(
                  height: 15,
                ),
                TwoTextedColumn(
                  text1: 'next_match'.tr,
                  text2: '   ${'no_dates_earrings'.tr}',
                  color2: kgrey1,
                ),
                SizedBox(
                  height: 25,
                ),
                MyButton(
                  onTap: () {},
                  buttonText: 'schedule'.tr,
                  mBottom: 15,
                ),
                MyButton(
                  onTap: () {},
                  buttonText: 'send_notification'.tr,
                  fillColor: kwhite,
                  outlineColor: kpurple1,
                  fontColor: kpurple1,
                  mBottom: 40,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget ProfileInfoCard(
    {String? name, String? gamesNo, String? win, String? lose}) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    decoration:
        BoxDecoration(borderRadius: BorderRadius.circular(10), color: kgrey2),
    child: Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: NetworkImage(dummyImage),
        ),
        SizedBox(
          width: 15,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(
              text: name ?? 'David Anderson',
              size: 19,
              color: kblack2,
              weight: FontWeight.bold,
            ),
            MyText(
              text: 'games_played_count'.trParams({'count': gamesNo ?? '204'}),
              size: 14,
              color: kblack2,
              weight: FontWeight.w500,
            ),
            Row(
              children: [
                MyText(
                  text: 'win_count'.trParams({'count': win ?? '160'}),
                  size: 14,
                  color: kteal,
                  weight: FontWeight.bold,
                  paddingRight: 10,
                ),
                MyText(
                  text: 'lose_count'.trParams({'count': lose ?? '100'}),
                  size: 14,
                  color: kred,
                  weight: FontWeight.bold,
                ),
              ],
            )
          ],
        )
      ],
    ),
  );
}
