import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Referee/IdentityVerification/ScanDocsBack.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/identity_verification_controller.dart';
import 'package:orland_sports/generated/assets.dart';

class RefereeScanDocs extends StatelessWidget {
  const RefereeScanDocs({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<IdentityVerificationController>();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -16,
          left: 0,
          right: 0,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 14),
            height: 20,
            decoration: BoxDecoration(
              color: kwhite.withOpacity(.6),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
        ),
        Container(
          height: Get.height * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            color: kwhite,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Image.asset(
                      Assets.imagesDivider,
                      width: 40,
                      height: 4,
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    MyText(
                      text: scanDocumentFront,
                      color: kpurple1,
                      size: 24,
                      weight: FontWeight.bold,
                      textAlign: TextAlign.center,
                    ),
                    MyText(
                      text: scanFrontPagePrompt,
                      color: kgrey1,
                      size: 14,
                      weight: FontWeight.w500,
                      paddingBottom: 25,
                      textAlign: TextAlign.center,
                    ),
                    Obx(
                      () => GestureDetector(
                        onTap: () => controller.captureFrontImage(),
                        child: controller.frontImage.value != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  controller.frontImage.value!,
                                  width: 348,
                                  height: 263,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : CommonImageView(
                                imagePath: Assets.imagesScan,
                                width: 348,
                                height: 263,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              Obx(
                () => MyText(
                  text: controller.frontImage.value != null
                      ? 'Front captured! Tap image to retake.'
                      : holdStill,
                  color: kpurple1,
                  size: controller.frontImage.value != null ? 16 : 22,
                  weight: FontWeight.bold,
                  textAlign: TextAlign.center,
                  paddingBottom: 40,
                ),
              ),
              Obx(
                () => MyButton(
                  onTap: () async {
                    if (controller.frontImage.value == null) {
                      final captured = await controller.captureFrontImage();
                      if (captured) {
                        Get.bottomSheet(RefereeScanDocsBack(),
                            isScrollControlled: true);
                      }
                    } else {
                      Get.bottomSheet(RefereeScanDocsBack(),
                          isScrollControlled: true);
                    }
                  },
                  buttonText:
                      controller.frontImage.value != null ? continuee : capture,
                  mBottom: 40,
                  mhoriz: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
