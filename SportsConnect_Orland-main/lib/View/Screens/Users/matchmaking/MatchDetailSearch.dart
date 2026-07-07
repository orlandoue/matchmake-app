import 'package:flutter/material.dart';
import 'package:orland_sports/View/Widgets/DialogBoxes.dart';
import 'package:orland_sports/View/Widgets/MatchDetailContainer.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/generated/assets.dart';

class MatchDetailAfterSearch extends StatelessWidget {
  final bool? twoPlayer;
  const MatchDetailAfterSearch({super.key, this.twoPlayer=false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
          title: matchDetail,
          haveBackButton: true,
          centerTitle: false,
          actions: [
            IconButton(
                onPressed: () {
                      SuccessDialog.ShowshareLinkdialog();
                },
                icon: Image.asset(
                  Assets.imagesShare,
                  width: 20,
                  height: 20,
                ))
          ]),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                Matchdetailcontainer(
                  twoPlayer: twoPlayer,
                ),
                SizedBox(
                  height: 20,
                ),
                Column(
                  children: [
                    Row(
                 
                      children: [
                        Expanded(
                          child: MyText(
                            text: 'Mario Court',
                            size: 16,
                            weight: FontWeight.bold,
                            color: kpurple1,
                          ),
                        ),
               
                      ],
                    ),
                    SizedBox(height: 5),
                    // Rating and Reviews
                    Row(
                      children: [
                        Image.asset(
                          Assets.imagesStar,
                          width: 18,
                          height: 18,
                        ),
                        MyText(
                          text: '5.0 (25 reviews)',
                          size: 14,
                          color: kblack2,
                          paddingLeft: 5,
                        ),
                        Spacer(),
                        // MyText(
                        //   text:direction,
                        //   size: 14,
                        //   weight: FontWeight.w400,
                        //   color: kgrey1,
                        // ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                MyText(
                  text: 'Main St. 2, Phase 3, Islamabad',
                  size: 14,
                  weight: FontWeight.w400,
                  color: kgrey1,
                ),
                MyText(
                  text: '2 km away\n10:00 AM , 20-12-2025',
                  size: 14,
                  weight: FontWeight.w400,
                  color: kgrey1,
                ),
                MyText(
                  paddingTop: 15,
                  text: 'Price',
                  size: 14,
                  weight: FontWeight.w700,
                  color: kblack,
                ),
                MyText(
                  text: "x1 Pase",
                  size: 14,
                  weight: FontWeight.w400,
                  color: kpurple1,
                  paddingBottom: 20,
                ),
                // MyButton(
                //   onTap: () {
                //     SuccessDialog.ShowshareLinkdialog();
                //     //Get.to(() => ReviewSummary());
                //   },
                //   buttonText: play,
                //   mBottom: 40,
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
