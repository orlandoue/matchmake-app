import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Referee/Auth/Login/LoginScreen.dart';
import 'package:orland_sports/View/Screens/Referee/Auth/SignUp/OTPVerification.dart';
import 'package:orland_sports/View/Widgets/Checkbox.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/View/Widgets/myTextField.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/referee_auth_controller.dart';
import 'package:orland_sports/generated/assets.dart';

class ReferreCreateAccount extends StatelessWidget {
  const ReferreCreateAccount({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RefereeAuthController>();

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(haveBackButton: false),
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
                  text: 'create_an_account'.tr,
                  color: kpurple1,
                  size: 24,
                  weight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                MyText(
                  text: 'start_finding_matches'.tr,
                  color: kgrey1,
                  size: 14,
                  weight: FontWeight.w500,
                  paddingBottom: 15,
                  textAlign: TextAlign.center,
                ),
                MyTextField(
                  hint: 'your_name_here'.tr,
                  controller: controller.nameController,
                  focusedFilledColor: kpurple1.withOpacity(0.05),
                ),
                MyTextField(
                  hint: 'your_email_here'.tr,
                  controller: controller.emailController,
                  focusedFilledColor: kpurple1.withOpacity(0.05),
                ),
                Obx(() => MyTextField(
                      hint: 'create_password'.tr,
                      controller: controller.passwordController,
                      isObSecure: !controller.isPasswordVisible.value,
                      suffixIcon: GestureDetector(
                        onTap: controller.togglePasswordVisibility,
                        child: Icon(
                          controller.isPasswordVisible.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: kgrey1,
                        ),
                      ),
                      focusedFilledColor: kpurple1.withOpacity(0.05),
                    )),
                Obx(() => MyTextField(
                      hint: 'retype_password'.tr,
                      controller: controller.confirmPasswordController,
                      isObSecure: !controller.isConfirmPasswordVisible.value,
                      suffixIcon: GestureDetector(
                        onTap: controller.toggleConfirmPasswordVisibility,
                        child: Icon(
                          controller.isConfirmPasswordVisible.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: kgrey1,
                        ),
                      ),
                      focusedFilledColor: kpurple1.withOpacity(0.05),
                    )),
                SizedBox(
                  height: 10,
                ),
                Obx(() => Row(
                      children: [
                        CustomCheckBox(
                          isActive: controller.agreeToTerms.value,
                          onTap: controller.toggleTermsAgreement,
                          iscircle: false,
                        ),
                        Row(
                          children: [
                            MyText(
                              text: 'agree_to'.tr,
                              color: kgrey1,
                              size: 14,
                              weight: FontWeight.w600,
                              paddingLeft: 6,
                            ),
                            MyText(
                              text: 'terms'.tr,
                              color: kpurple1,
                              size: 14,
                              weight: FontWeight.w700,
                            ),
                          ],
                        ),
                      ],
                    )),
                SizedBox(
                  height: 20,
                ),
                Obx(() => MyButton(
                      onTap: controller.isLoading.value
                          ? () {}
                          : () async {
                              final success = await controller.signUp();
                              if (success) {
                                Get.bottomSheet(
                                  const RefereeOTPVerfication(),
                                  isScrollControlled: true,
                                );
                              }
                            },
                      buttonText: controller.isLoading.value
                          ? 'please_wait'.tr
                          : 'register'.tr,
                      mBottom: 20,
                    )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Divider(
                        color: kgrey2,
                        thickness: 1,
                        indent: 5,
                        endIndent: 10,
                      ),
                    ),
                    MyText(
                      text: 'or_continue_with'.tr,
                      size: 14,
                      color: kgrey1,
                      weight: FontWeight.w500,
                    ),
                    Expanded(
                      child: Divider(
                        color: kgrey2,
                        thickness: 1,
                        indent: 10,
                        endIndent: 5,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LoginOptions(
                      icon: Assets.imagesGoogle,
                      ontap: () {
                        controller.signInWithGoogle().then((success) {
                          if (success) {
                            controller.navigateAfterLogin();
                          }
                        });
                      },
                    ),
                    LoginOptions(
                      icon: Assets.imagesApple,
                      ontap: () {},
                    ),
                    LoginOptions(
                      icon: Assets.imagesFacebook,
                      ontap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MyText(
                text: 'already_have_account'.tr,
                color: kgrey1,
                paddingLeft: 2,
                size: 15,
                weight: FontWeight.w400,
              ),
              MyText(
                text: 'login'.tr,
                color: kpurple1,
                size: 16,
                weight: FontWeight.w700,
                onTap: () {
                  Get.to(() => RefereeLoginScreen());
                },
              ),
            ],
          ),
          SizedBox(
            height: 40,
          )
        ],
      ),
    );
  }
}
