import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myTextField.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/change_password_controller.dart';

class ChangePassword extends StatelessWidget {
  const ChangePassword({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChangePasswordController());

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'security'.tr,
        haveBackButton: true,
        centerTitle: false,
      ),
      body: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                shrinkWrap: true,
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  Obx(() => MyTextField(
                        controller: controller.currentPasswordController,
                        hint: 'current_password'.tr,
                        isObSecure: !controller.isCurrentPasswordVisible.value,
                        suffixIcon: GestureDetector(
                          onTap: controller.toggleCurrentPasswordVisibility,
                          child: Icon(
                            controller.isCurrentPasswordVisible.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: kgrey1.withOpacity(0.5),
                          ),
                        ),
                        focusedFilledColor: kpurple1.withOpacity(0.05),
                      )),
                  Obx(() => MyTextField(
                        controller: controller.newPasswordController,
                        hint: 'create_new_password'.tr,
                        isObSecure: !controller.isNewPasswordVisible.value,
                        suffixIcon: GestureDetector(
                          onTap: controller.toggleNewPasswordVisibility,
                          child: Icon(
                            controller.isNewPasswordVisible.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: kgrey1.withOpacity(0.5),
                          ),
                        ),
                        focusedFilledColor: kpurple1.withOpacity(0.05),
                      )),
                  Obx(() => MyTextField(
                        controller: controller.confirmPasswordController,
                        hint: 'retype_new_password'.tr,
                        isObSecure: !controller.isConfirmPasswordVisible.value,
                        suffixIcon: GestureDetector(
                          onTap: controller.toggleConfirmPasswordVisibility,
                          child: Icon(
                            controller.isConfirmPasswordVisible.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: kgrey1.withOpacity(0.5),
                          ),
                        ),
                        focusedFilledColor: kpurple1.withOpacity(0.05),
                      )),
                ],
              ),
            ),
            Obx(() => MyButton(
                  onTap: controller.isLoading.value
                      ? () {}
                      : () => controller.changePassword(),
                  buttonText: controller.isLoading.value
                      ? 'updating'.tr
                      : 'update_password'.tr,
                  mBottom: 60,
                  mhoriz: 20,
                )),
          ],
        ),
      ),
    );
  }
}
