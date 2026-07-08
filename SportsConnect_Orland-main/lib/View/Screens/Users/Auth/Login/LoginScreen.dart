import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/Auth/Login/ForgetPassword.dart';
import 'package:orland_sports/View/Screens/Users/Auth/SignUp/CreateAccount.dart';
import 'package:orland_sports/View/Widgets/Checkbox.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/View/Widgets/myTextField.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/auth_controller.dart';
import 'package:orland_sports/generated/assets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

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
                  controller: authController.loginEmailController,
                  keyboardType: TextInputType.emailAddress,
                  focusedFilledColor: kpurple1.withOpacity(0.05),
                ),
                Obx(
                  () => MyTextField(
                    hint: 'your_password_here'.tr,
                    controller: authController.loginPasswordController,
                    isObSecure: !authController.isPasswordVisible.value,
                    suffixIcon: GestureDetector(
                      onTap: authController.togglePasswordVisibility,
                      child: Icon(
                        authController.isPasswordVisible.value
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: kgrey1,
                      ),
                    ),
                    focusedFilledColor: kpurple1.withOpacity(0.05),
                  ),
                ),
                MyText(
                  text: 'forget_password'.tr,
                  color: kgrey1,
                  size: 14,
                  weight: FontWeight.w600,
                  paddingBottom: 15,
                  onTap: () {
                    Get.bottomSheet(
                      const ForgetPassword(),
                      isScrollControlled: true,
                    );
                  },
                  textAlign: TextAlign.right,
                ),
                Obx(
                  () => Row(
                    children: [
                      CustomCheckBox(
                        isActive: authController.rememberMe.value,
                        onTap: authController.toggleRememberMe,
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
                  ),
                ),
                const SizedBox(height: 20),
                Obx(
                  () => MyButton(
                    onTap: authController.isLoading.value
                        ? () {}
                        : () {
                            authController.login().then((success) {
                              if (success) {
                                authController.navigateAfterLogin();
                              }
                            });
                          },
                    buttonText: authController.isLoading.value
                        ? 'signing_in'.tr
                        : 'login'.tr,
                    mBottom: 20,
                  ),
                ),
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LoginOptions(
                      icon: Assets.imagesGoogle,
                      ontap: () {
                        authController.signInWithGoogle().then((success) {
                          if (success) {
                            authController.navigateAfterLogin();
                          }
                        });
                      },
                    ),
                    LoginOptions(
                      icon: Assets.imagesApple,
                      ontap: () {
                        // TODO: Implement Apple Sign In
                      },
                    ),
                    LoginOptions(
                      icon: Assets.imagesFacebook,
                      ontap: () {
                        // TODO: Implement Facebook Sign In
                      },
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
                  Get.to(() => const CreateAccount());
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
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
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kgrey2),
        ),
        child: Center(
          child: CommonImageView(
            imagePath: icon,
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }
}
