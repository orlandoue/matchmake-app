import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Referee/Auth/Login/ForgetPassword.dart';
import 'package:orland_sports/View/Screens/Referee/Auth/SignUp/CreateAccount.dart';
import 'package:orland_sports/View/Widgets/Checkbox.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/View/Widgets/myTextField.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/referee_auth_controller.dart';
import 'package:orland_sports/generated/assets.dart';

class RefereeLoginScreen extends StatelessWidget {
  const RefereeLoginScreen({super.key});

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
                  text: 'welcome_back'.tr,
                  color: kpurple1,
                  size: 24,
                  weight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
                MyText(
                  text: 'enter_credentials'.tr,
                  color: kgrey1,
                  size: 14,
                  weight: FontWeight.w500,
                  paddingBottom: 15,
                  textAlign: TextAlign.center,
                ),
                MyTextField(
                  hint: 'your_email_here'.tr,
                  controller: controller.loginEmailController,
                  focusedFilledColor: kpurple1.withOpacity(0.05),
                ),
                Obx(() => MyTextField(
                      hint: 'your_password_here'.tr,
                      controller: controller.loginPasswordController,
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
                MyText(
                    text: 'forget_password'.tr,
                    color: kgrey1,
                    size: 14,
                    weight: FontWeight.w600,
                    paddingBottom: 15,
                    onTap: () {
                      Get.bottomSheet(ReferreForgetPassword(),
                          isScrollControlled: true);
                    },
                    textAlign: TextAlign.right),
                Obx(() => Row(
                      children: [
                        CustomCheckBox(
                          isActive: controller.rememberMe.value,
                          onTap: controller.toggleRememberMe,
                          iscircle: false,
                        ),
                        MyText(
                          text: 'remember_me'.tr,
                          color: kpurple1,
                          size: 14,
                          weight: FontWeight.w600,
                          paddingLeft: 6,
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
                              final success = await controller.login();
                              if (success) {
                                controller.navigateAfterLogin();
                              }
                            },
                      buttonText:
                          controller.isLoading.value ? 'please_wait'.tr : 'login'.tr,
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
                text: 'dont_have_account'.tr,
                color: kgrey1,
                size: 15,
                weight: FontWeight.w400,
                paddingRight: 6,
              ),
              MyText(
                text: 'create_account'.tr,
                color: kpurple1,
                size: 16,
                weight: FontWeight.w700,
                onTap: () {
                  Get.to(() => ReferreCreateAccount());
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

class LoginOptions extends StatelessWidget {
  final String icon;
  final VoidCallback ontap;
  const LoginOptions({
    super.key,
    required this.icon,
    required this.ontap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ontap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 26, vertical: 15),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kgrey2)),
        child: Center(
            child: CommonImageView(
          imagePath: icon,
          width: 21,
          height: 21,
        )),
      ),
    );
  }
}
