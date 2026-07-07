import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Referee/Home/MatchDetails/scan.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/ManageMatch.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/generated/assets.dart';
import 'package:orland_sports/main.dart';

class ReferreMatchDetail extends StatelessWidget {
  ReferreMatchDetail({super.key});

  bool isReady = false;

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
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                MyText(
                  paddingTop: 15,
                  text: matchstartin,
                  size: 16,
                  weight: FontWeight.w600,
                  color: kblack2,
                  paddingBottom: 4,
                  textAlign: TextAlign.center,
                ),
                MyText(
                  text: '1h 2 min',
                  size: 24,
                  weight: FontWeight.w700,
                  color: kblack2,
                  paddingBottom: 15,
                  textAlign: TextAlign.center,
                ),
                manageMatchcard(
                  border: kgrey2,
                  bgColor: kwhite,
                  textColor: kgrey1,
                  statusColor: kgrey1,
                  Statustext: '02:00 pm',
                  weight: FontWeight.w400,
                ),
                MyText(
                  paddingTop: 15,
                  text: scanqr,
                  size: 16,
                  weight: FontWeight.w700,
                  color: kblack2,
                  paddingBottom: 4,
                ),
                Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: kpurple2.withOpacity(0.3)),
                  padding: EdgeInsets.all(10),
                  child: MyText(
                    text: scanqrtext,
                    color: kblack2,
                    size: 13,
                    weight: FontWeight.w400,
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MemberContainer(
                      size: 60,
                      textColor: kgrey1,
                    ),
                    scanContainer(() {
                      Get.to(() => ScanToMatch());
                    }),
//if scan successful, then shownthe ready text row stated below
                    // Row(
                    //   children: [
                    //     Icon(
                    //       Icons.check,
                    //       color: kpurple1,
                    //       size: 19,
                    //     ),
                    //     MyText(
                    //       text: 'Ready!',
                    //       color: kpurple1,
                    //       size: 16,
                    //       weight: FontWeight.w600,
                    //       paddingLeft: 4,
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MemberContainer(
                      size: 60,
                      textColor: kgrey1,
                    ),
                    //same here
                    scanContainer(() {
                      Get.to(() => ScanToMatch());
                    })
                  ],
                ),
                SizedBox(
                  height: 40,
                ),
                MyButton(
                  onTap: () {
                    //  Get.to(() => ScanToMatch());
                  },
                  buttonText: confirmstart,
                  // fillColor: kgrey1.withOpacity(0.6),
                  // fontColor: kwhite,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

//here widgets and etc
  Widget scanContainer(VoidCallback ontap) {
    return GestureDetector(
      onTap: ontap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: kgrey2,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
                child: Image.asset(
              Assets.imagesQrCode,
              width: 24,
              height: 24,
            )),
          ),
          MyText(
            text: scan,
            color: kgrey1,
            paddingTop: 4,
            weight: FontWeight.w600,
            size: 14,
          )
        ],
      ),
    );
  }
}

class MemberContainer extends StatelessWidget {
  final String? name, image;
  final double? size;
  final Color? textColor;
  final VoidCallback? ontap;
  const MemberContainer(
      {super.key,
      this.name,
      this.image,
      this.size,
      this.textColor,
      this.ontap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ontap,
      child: Column(
        children: [
          CommonImageView(
            url: image ?? dummyImage,
            width: size ?? 82,
            height: size ?? 82,
            radius: 15,
          ),
          MyText(
            text: name ?? 'yin',
            color: textColor ?? kblack2,
            paddingTop: 4,
            weight: FontWeight.w700,
            size: 14,
          )
        ],
      ),
    );
  }
}
