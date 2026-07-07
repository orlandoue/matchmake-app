import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myTextField.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/contact_controller.dart';

class ContactUs extends StatelessWidget {
  const ContactUs({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ContactController());

    return Scaffold(
      backgroundColor: kwhite,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                MyTextField(
                  hint: 'full_name'.tr,
                  controller: controller.nameController,
                  focusedFilledColor: kpurple1.withOpacity(0.05),
                ),
                MyTextField(
                  hint: 'email_address'.tr,
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  focusedFilledColor: kpurple1.withOpacity(0.05),
                ),
                MyTextField(
                  hint: 'phone_number'.tr,
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  focusedFilledColor: kpurple1.withOpacity(0.05),
                ),
                MyTextField(
                  hint: 'description'.tr,
                  controller: controller.descriptionController,
                  maxLines: 5,
                  focusedFilledColor: kpurple1.withOpacity(0.05),
                ),
              ],
            ),
          ),
          Obx(() => MyButton(
                onTap: controller.isLoading.value
                    ? () {}
                    : () => controller.sendInquiry(),
                buttonText: controller.isLoading.value ? 'sending'.tr : 'send'.tr,
                mBottom: 60,
                mhoriz: 20,
              ))
        ],
      ),
    );
  }
}
