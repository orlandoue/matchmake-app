import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Referee/Home/MatchDetails/match_details.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/DialogBoxes.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/generated/assets.dart';

class ScanToMatch extends StatelessWidget {
  const ScanToMatch({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
          title: 'scan_qr_code'.tr,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              SuccessDialog.showSuccessDialog(identitydismatched,
                 scannotmatchtext,
                  ButtonText: scanagain,
                  image: Assets.imagesWarningCircle, titleColor: kred,ontap: () {
                    Navigator.pop(Get.context!);
                    Navigator.pop(Get.context!);
                  },);
            },
            child: Center(
              child: CommonImageView(
                imagePath: Assets.imagesScan2,
                height: 250,
                width: 240,
              ),
            ),
          )
        ],
      ),
    );
  }
}
