import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Referee/Auth/Login/LoginScreen.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/const/app_fonts.dart';
import 'package:orland_sports/generated/assets.dart';

class RefereeChooseLogin extends StatelessWidget {
  const RefereeChooseLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kwhite,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                SizedBox(
                  height: 50,
                ),
                CommonImageView(
                  imagePath: Assets.imagesFinalSplash,
                  width: 270,
                  height: 360,
                  fit: BoxFit.contain,
                ),
                MyText(
                  text: 'matchmake'.tr,
                  color: kpurple1,
                  size: 32,
                  weight: FontWeight.w900,
                  textAlign: TextAlign.center,
                  paddingTop: 10,
                ),
                MyText(
                  text: 'setup_matches_track_progress'.tr,
                  color: kgrey1,
                  size: 14,
                  weight: FontWeight.w400,
                  paddingBottom: 50,
                  textAlign: TextAlign.center,
                ),
                // MyButton(
                //   onTap: () {
                //     Get.to(() => ReferreCreateAccount());
                //   },
                //   buttonText: register,
                //   mBottom: 15,
                // ),
                MyButton(
                  onTap: () {
                    Get.to(() => RefereeLoginScreen());
                  },
                  buttonText: 'login'.tr,
                  fillColor: kwhite,
                  fontColor: kpurple1,
                  outlineColor: kpurple1,
                ),
                SizedBox(
                  height: 20,
                ),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'agreement_prompt'.tr,
                        style: TextStyle(
                          color: kgrey1,
                          fontSize: 14,
                          fontFamily: AppFonts.boston,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextSpan(
                        text: 'terms_of_service'.tr,
                        style: TextStyle(
                          color: kpurple1,
                          fontSize: 14,
                          fontFamily: AppFonts.boston,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: ' & ',
                        style: TextStyle(
                          color: kgrey1,
                          fontSize: 14,
                          fontFamily: AppFonts.boston,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextSpan(
                        text: 'privacy_policy'.tr,
                        style: TextStyle(
                          color: kpurple1,
                          fontSize: 14,
                          fontFamily: AppFonts.boston,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
