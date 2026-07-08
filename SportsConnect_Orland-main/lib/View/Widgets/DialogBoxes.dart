import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/ReviewSummary.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/View/Widgets/myTextField.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/generated/assets.dart';

class SuccessDialog {
  static void showSuccessDialog(String title, String message,
      {String? ButtonText,
      VoidCallback? ontap,
      String? image,
      Color? titleColor}) {
    Get.dialog(
      AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 30.0),
        contentPadding: EdgeInsets.only(bottom: 30, left: 5, right: 5),
        backgroundColor: kwhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Image.asset(
              image ?? Assets.imagesSuccess,
              width: 100,
              height: 100,
            ),
            SizedBox(height: 5),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText(
                text: title,
                color: titleColor ?? kpurple1,
                size: 20,
                weight: FontWeight.bold,
                paddingTop: 5,
              ),
              MyText(
                text: message,
                color: kgrey1,
                size: 14,
                weight: FontWeight.w400,
                paddingBottom: 20,
                textAlign: TextAlign.center,
              ),
              MyButton(
                onTap: ontap ??
                    () {
                      Get.back();
                    },
                buttonText: ButtonText ?? 'continue_text'.tr,
                fontSize: 14,
                radius: 15,
              )
            ],
          ),
        ),
      ),
    );
  }

  static void ShowshareLinkdialog() {
    Get.dialog(
      AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 30.0),
        contentPadding: EdgeInsets.only(bottom: 30, left: 5, right: 5),
        backgroundColor: kwhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Image.asset(
              Assets.imagesLink,
              width: 100,
              height: 100,
            ),
            SizedBox(height: 20),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText(
                text: 'invitation_link'.tr,
                color: kpurple1,
                size: 20,
                weight: FontWeight.bold,
                paddingTop: 5,
              ),
              MyText(
                text: 'invitation_link_description'.tr,
                color: kgrey1,
                size: 14,
                weight: FontWeight.w400,
                paddingBottom: 20,
                textAlign: TextAlign.center,
              ),
              MyTextField(
                hint: 'https://invitelink/playerA?/1bcf4r',
                filledColor: kgrey2,
                suffixIcon: Icon(
                  Icons.copy,
                  color: kgrey1.withOpacity(0.4),
                  size: 18,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.to(() => ReviewSummary(onConfirm: () async => true));
                    },
                    child: CommonImageView(
                      imagePath: Assets.imagesMail,
                      width: 54,
                      height: 54,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: CommonImageView(
                      imagePath: Assets.imagesFacebook2,
                      width: 54,
                      height: 54,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: CommonImageView(
                      imagePath: Assets.imagesInsta,
                      width: 54,
                      height: 54,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: CommonImageView(
                      imagePath: Assets.imagesWhatsapp,
                      width: 54,
                      height: 54,
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  static void invitationDialog(String title, {Color? titleColor}) {
    Get.dialog(
      AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 26),
        contentPadding: EdgeInsets.only(
          bottom: 30,
        ),
        backgroundColor: kwhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Image.asset(
          Assets.imagesLink,
          width: 120,
          height: 120,
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyText(
                text: 'invitation_code'.tr,
                color: kpurple1,
                size: 24,
                weight: FontWeight.w700,
                paddingBottom: 15,
                textAlign: TextAlign.center,
              ),
              MyText(
                text: 'type_invitation_code'.tr,
                color: kgrey1,
                size: 14,
                weight: FontWeight.w400,
                paddingBottom: 20,
                textAlign: TextAlign.center,
              ),
              MyTextField(
                hint: '|',
                filledColor: kgrey2,
                bordercolor: kgrey2,
                focusedFilledColor: kgrey2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


//