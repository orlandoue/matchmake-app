import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/Auth/Login/LoginScreen.dart';
import 'package:orland_sports/View/Screens/Users/Auth/SignUp/OTPVerification.dart';
import 'package:orland_sports/View/Widgets/Checkbox.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/View/Widgets/myTextField.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/auth_controller.dart';
import 'package:orland_sports/generated/assets.dart';

class CreateAccount extends StatelessWidget {
  const CreateAccount({super.key});

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
                  controller: authController.nameController,
                  focusedFilledColor: kpurple1.withOpacity(0.05),
                ),
                MyTextField(
                  hint: 'your_email_here'.tr,
                  controller: authController.emailController,
                  keyboardType: TextInputType.emailAddress,
                  focusedFilledColor: kpurple1.withOpacity(0.05),
                ),
                Obx(
                  () => MyTextField(
                    hint: 'create_password'.tr,
                    controller: authController.passwordController,
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
                Obx(
                  () => MyTextField(
                    hint: 'retype_password'.tr,
                    controller: authController.confirmPasswordController,
                    isObSecure: !authController.isConfirmPasswordVisible.value,
                    suffixIcon: GestureDetector(
                      onTap: authController.toggleConfirmPasswordVisibility,
                      child: Icon(
                        authController.isConfirmPasswordVisible.value
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: kgrey1,
                      ),
                    ),
                    focusedFilledColor: kpurple1.withOpacity(0.05),
                  ),
                ),
                const SizedBox(height: 10),
                Obx(
                  () => Row(
                    children: [
                      CustomCheckBox(
                        isActive: authController.agreeToTerms.value,
                        onTap: authController.toggleTermsAgreement,
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
                  ),
                ),
                const SizedBox(height: 20),
                Obx(
                  () => MyButton(
                    onTap: authController.isLoading.value
                        ? () {}
                        : () {
                            authController.signUp().then((success) {
                              if (success) {
                                Get.bottomSheet(
                                  const OTPVerfication(),
                                  isScrollControlled: true,
                                );
                              }
                            });
                          },
                    buttonText: authController.isLoading.value
                        ? 'please_wait'.tr
                        : 'register'.tr,
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
                  Get.to(() => const LoginScreen());
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
