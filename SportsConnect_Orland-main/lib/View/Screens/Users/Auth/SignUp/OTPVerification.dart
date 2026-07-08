import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/ProfileCompletion/Profileinfo1.dart';
import 'package:orland_sports/View/Widgets/DialogBoxes.dart';
import 'package:orland_sports/View/Widgets/Pinput.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/auth_controller.dart';
import 'package:orland_sports/generated/assets.dart';

class OTPVerfication extends StatelessWidget {
  const OTPVerfication({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -18,
          left: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            height: 20,
            decoration: BoxDecoration(
              color: kwhite.withOpacity(.6),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
        ),
        Container(
          height: Get.height * 0.8,
          decoration: const BoxDecoration(
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
                    const SizedBox(height: 20),
                    MyText(
                      text: 'otp_verification'.tr,
                      color: kpurple1,
                      size: 24,
                      weight: FontWeight.bold,
                      textAlign: TextAlign.center,
                    ),
                    MyText(
                      text: 'enter_otp_prompt'.tr,
                      color: kgrey1,
                      size: 14,
                      weight: FontWeight.w500,
                      paddingBottom: 15,
                      textAlign: TextAlign.center,
                    ),
                    MyPinCode(
                      controller: authController.otpController,
                      onChanged: (value) {},
                      onCompleted: (value) {
                        print("Completed: $value");
                      },
                    ),
                  ],
                ),
              ),
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MyText(
                      text: authController.otpResendTimer.value > 0
                          ? '${authController.otpResendTimer.value.toString().padLeft(2, '0')}s '
                          : '',
                      color: kgrey1,
                      size: 15,
                      weight: FontWeight.w400,
                    ),
                    MyText(
                      text: 'resend_code'.tr,
                      color: authController.otpResendTimer.value > 0
                          ? kgrey1
                          : kpurple1,
                      size: 16,
                      weight: FontWeight.w700,
                      onTap: authController.otpResendTimer.value > 0
                          ? null
                          : () {
                              authController.resendOtp();
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Obx(
                () => MyButton(
                  onTap: authController.isLoading.value
                      ? () {}
                      : () {
                          final otp = authController.otpController.text.trim();
                          if (otp.length < 6) {
                            return;
                          }

                          authController.verifyOtp(otp).then((isSuccess) {
                            if (isSuccess) {
                              Navigator.pop(Get.context!); // Close bottom sheet
                              SuccessDialog.showSuccessDialog(
                                ontap: () {
                                  Get.offAll(() => const ProfileInfo1());
                                },
                                'success'.tr,
                                'account_verified_prompt'.tr,
                              );
                            }
                          });
                        },
                  buttonText:
                      authController.isLoading.value ? 'verifying'.tr : 'confirm'.tr,
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
