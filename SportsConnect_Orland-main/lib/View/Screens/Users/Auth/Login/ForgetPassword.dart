import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/Auth/Login/LoginScreen.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/View/Widgets/myTextField.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/auth_controller.dart';
import 'package:orland_sports/generated/assets.dart';

class ForgetPassword extends StatelessWidget {
  const ForgetPassword({super.key});

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
                      text: 'forgot_password_title'.tr,
                      color: kpurple1,
                      size: 24,
                      weight: FontWeight.bold,
                      textAlign: TextAlign.center,
                    ),
                    MyText(
                      text: 'forgot_password_prompt'.tr,
                      color: kgrey1,
                      size: 14,
                      weight: FontWeight.w500,
                      paddingBottom: 15,
                      textAlign: TextAlign.center,
                    ),
                    MyTextField(
                      hint: 'your_email_here'.tr,
                      controller: authController.forgotPasswordEmailController,
                      keyboardType: TextInputType.emailAddress,
                      focusedFilledColor: kpurple1.withOpacity(0.05),
                    ),
                  ],
                ),
              ),
              Obx(
                () => MyButton(
                  onTap: authController.isLoading.value
                      ? () {}
                      : () {
                          authController
                              .sendPasswordResetEmail()
                              .then((success) {
                            if (success) {
                              Navigator.pop(Get.context!); // Close bottom sheet
                            }
                          });
                        },
                  buttonText: authController.isLoading.value
                      ? 'please_wait'.tr
                      : 'send_password_reset_link'.tr,
                  mBottom: 10,
                  mhoriz: 20,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MyText(
                    text: 'back_to'.tr,
                    paddingLeft: 4,
                    color: kgrey1,
                    size: 15,
                    weight: FontWeight.w400,
                  ),
                  MyText(
                    text: 'login'.tr,
                    color: kpurple1,
                    size: 16,
                    weight: FontWeight.w700,
                    onTap: () {
                      Navigator.pop(Get.context!); // Close bottom sheet
                      Get.to(() => const LoginScreen());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }
}
