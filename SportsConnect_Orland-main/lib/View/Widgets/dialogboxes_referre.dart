import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Referee/Home/MatchDetails/match_details.dart';
import 'package:orland_sports/View/Widgets/StarRatings.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/View/Widgets/myTextField.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';

class ReferreDialog {
  static void AcceptMatchDialog(String title, {Color? titleColor}) {
    Get.dialog(
      AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 25.0),
        contentPadding: EdgeInsets.only(bottom: 30, left: 5, right: 5),
        backgroundColor: kwhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            MyText(
              text: title,
              color: titleColor ?? kpurple1,
              size: 22,
              weight: FontWeight.bold,
              paddingBottom: 4,
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText(
                text:accepttobegin,
                color: kgrey1,
                size: 14,
                weight: FontWeight.w400,
                paddingBottom: 20,
                textAlign: TextAlign.center,
              ),
              MyButton(
                onTap: () {},
                buttonText: accept,
                fontSize: 14,
                radius: 15,
                mBottom: 15,
              ),
              MyButton(
                onTap: () {},
                buttonText: decline,
                outlineColor: kpurple1,
                fillColor: kwhite,
                fontColor: kpurple1,
                fontSize: 14,
                radius: 15,
              )
            ],
          ),
        ),
      ),
    );
  }

//

  static void WintMatchDialog(String title, {Color? titleColor}) {
    Get.dialog(
      AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 25.0),
        contentPadding: EdgeInsets.only(bottom: 30, left: 5, right: 5),
        backgroundColor: kwhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [MemberContainer()],
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText(
                text: '$title ${winneris}',
                color: kpurple1,
                size: 24,
                weight: FontWeight.w700,
                paddingBottom: 5,
                textAlign: TextAlign.center,
              ),
              MyText(
                text:
                    '$title ${continuetorate}',
                color: kgrey1,
                size: 14,
                weight: FontWeight.w400,
                paddingBottom: 15,
                textAlign: TextAlign.center,
              ),
              MyButton(
                onTap: () {
                  ReferreDialog.RatingDialog('Yin');
                },
                buttonText: continuee,
                fontSize: 14,
                radius: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  ///Ratings dialog box

  static void RatingDialog(String title, {Color? titleColor}) {
    Get.dialog(
      AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 0),
        contentPadding: EdgeInsets.only(bottom: 30,),
        backgroundColor: kwhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [MemberContainer(
            size: 60,
          )],
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText(
                text: 'rate_title'.trParams({'title': title}),
                color: kblack2,
                size: 24,
                weight: FontWeight.w700,
                paddingBottom: 15,
                textAlign: TextAlign.center,
              ),
              Ratingcontainer(
                Sportsmanship,
              ),
              SizedBox(height: 24,),
              Ratingcontainer(
                SkillLevel,
              ),
              SizedBox(height: 24,),
              Ratingcontainer(
                OverallPerformance
              ),
              SizedBox(height: 24,),
              MyTextField(
                hint: leaveacomment,
                maxLines: 4,
              ),
              MyButton(
                onTap: () {
                  Navigator.pop(Get.context!);
                  Navigator.pop(Get.context!);
                },
                buttonText: continuee,
                fontSize: 14,
                radius: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget Ratingcontainer(String title) {
  return Container(
    child: Column(
      children: [
        MyText(
          text: title,
          size: 16,
          color: kpurple1,
          weight: FontWeight.w500,
       
        ),
        StarRating(
          rating: 5,
          size: 18,
        )
      ],
    ),
  );
}

//