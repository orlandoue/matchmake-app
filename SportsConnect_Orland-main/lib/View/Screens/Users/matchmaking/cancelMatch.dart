import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/BottomSheets.dart';
import 'package:orland_sports/View/Widgets/MatchDetailContainer.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/player_matches_controller.dart';
import 'package:orland_sports/generated/assets.dart';
import 'package:orland_sports/models/match_model.dart';

class CancelMatch extends StatelessWidget {
  final MatchModel? match;
  const CancelMatch({super.key, this.match});

  @override
  Widget build(BuildContext context) {
    final matchController = Get.find<PlayerMatchesController>();
    final court = match?.court;

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
          title: matchDetail,
          haveBackButton: true,
          centerTitle: false,
          actions: [
            IconButton(
                onPressed: () {},
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
                  match: match,
                  currentUserId: matchController.currentUserId,
                ),
                SizedBox(
                  height: 20,
                ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: MyText(
                            text: court?.name ?? 'Court',
                            size: 16,
                            weight: FontWeight.bold,
                            color: kpurple1,
                            maxLines: 1,
                            textOverflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Image.asset(
                          Assets.imagesForwardicon,
                          width: 30,
                          height: 30,
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    // Court type
                    Row(
                      children: [
                        Image.asset(
                          Assets.imagesStar,
                          width: 18,
                          height: 18,
                        ),
                        MyText(
                          text: court?.isIndoor == true ? 'indoor'.tr : 'outdoor'.tr,
                          size: 14,
                          color: kblack2,
                          paddingLeft: 5,
                        ),
                        Spacer(),
                        MyText(
                          text: match?.formattedDate ?? '',
                          size: 14,
                          weight: FontWeight.w400,
                          color: kgrey1,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                if (court?.address != null)
                  MyText(
                    text: court!.address!,
                    size: 14,
                    weight: FontWeight.w400,
                    color: kgrey1,
                  ),
                if (match != null)
                  MyText(
                    text: match!.timeRangeDisplay,
                    size: 14,
                    weight: FontWeight.w400,
                    color: kgrey1,
                  ),
                MyText(
                  paddingTop: 15,
                  text: description,
                  size: 14,
                  weight: FontWeight.w700,
                  color: kblack,
                ),
                MyText(
                  text: court?.description ?? 'no_description_available'.tr,
                  size: 14,
                  weight: FontWeight.w400,
                  color: kpurple1,
                  paddingBottom: 20,
                ),
                MyButton(
                  onTap: () {
                    Get.bottomSheet(CancelMatchBottomSheet(matchId: match?.id),
                        isScrollControlled: true);
                  },
                  buttonText: cancelMatch,
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
