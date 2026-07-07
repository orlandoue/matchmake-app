import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/DialogBoxes.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/auth_controller.dart';
import 'package:orland_sports/controllers/identity_verification_controller.dart';
import 'package:orland_sports/generated/assets.dart';

class ScanLiveImage extends StatelessWidget {
  const ScanLiveImage({super.key});

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
                      text: livePhotoScan,
                      color: kpurple1,
                      size: 24,
                      weight: FontWeight.bold,
                      textAlign: TextAlign.center,
                    ),
                    MyText(
                      text: livePhotoScanPrompt,
                      color: kgrey1,
                      size: 14,
                      weight: FontWeight.w500,
                      paddingBottom: 25,
                      textAlign: TextAlign.center,
                    ),
                    Obx(
                      () => GestureDetector(
                        onTap: () => controller.captureSelfieImage(),
                        child: Center(
                          child: Container(
                            height: 220,
                            width: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kgrey2,
                              image: controller.selfieImage.value != null
                                  ? DecorationImage(
                                      image: FileImage(
                                          controller.selfieImage.value!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              border: Border.all(color: kpurple1, width: 3),
                            ),
                            child: controller.selfieImage.value == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt,
                                          color: kpurple1, size: 48),
                                      SizedBox(height: 8),
                                      MyText(
                                        text: 'tap_to_take_selfie'.tr,
                                        color: kpurple1,
                                        size: 14,
                                        weight: FontWeight.w500,
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Obx(
                () => MyText(
                  text: controller.selfieImage.value != null
                      ? 'Selfie captured! Tap photo to retake.'
                      : holdStill,
                  color: kpurple1,
                  size: controller.selfieImage.value != null ? 16 : 22,
                  weight: FontWeight.bold,
                  textAlign: TextAlign.center,
                  paddingBottom: 40,
                ),
              ),
              Obx(
                () => MyButton(
                  onTap: controller.isLoading.value
                      ? () {}
                      : () async {
                          if (controller.selfieImage.value == null) {
                            final captured =
                                await controller.captureSelfieImage();
                            if (!captured) return;
                          }

                          // Submit all images
                          final authController = Get.find<AuthController>();
                          final userId = authController.currentUserId;
                          if (userId == null) return;

                          final verificationResult =
                              await controller.submitVerification(userId);

                          if (verificationResult) {
                            // Close all bottom sheets
                            if (Get.isBottomSheetOpen ?? false) {
                              Get.until(
                                  (route) => !(Get.isBottomSheetOpen ?? false));
                            }

                            SuccessDialog.showSuccessDialog(
                              success,
                              documentsUploadedSuccessfully,
                              ontap: () {
                                Get.back(); // Close the dialog
                              },
                            );
                          } else {
                            SuccessDialog.showSuccessDialog(
                              failed,
                              retryCapturePrompt,
                              ButtonText: tryAgain,
                              image: Assets.imagesFail,
                              ontap: () {
                                Get.back();
                              },
                            );
                          }
                        },
                  buttonText: controller.isLoading.value
                      ? 'Uploading...'
                      : controller.selfieImage.value != null
                          ? 'Submit Verification'
                          : capture,
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
