import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/MyDropDown.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/View/Widgets/myTextField.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/referee_auth_controller.dart';
import 'package:orland_sports/generated/assets.dart';

class ReferreEditProfile extends StatelessWidget {
  const ReferreEditProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RefereeAuthController>();

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'edit_profile'.tr,
        haveBackButton: true,
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                // Profile Image Section
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Obx(() {
                        final editImage = controller.editProfileImage.value;
                        final hasCurrentImage = controller.hasProfileImage;
                        final currentImageUrl = controller.profileImageUrl;

                        if (editImage != null) {
                          // Show selected image
                          return Container(
                            height: 90,
                            width: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: FileImage(editImage),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        } else if (hasCurrentImage && currentImageUrl != null) {
                          // Show current profile image
                          return Container(
                            height: 90,
                            width: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CommonImageView(
                                url: currentImageUrl,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        } else {
                          // Show placeholder
                          return Container(
                            height: 90,
                            width: 90,
                            decoration: BoxDecoration(
                              color: kgrey2,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.person,
                              color: kgrey1,
                              size: 50,
                            ),
                          );
                        }
                      }),
                      Positioned(
                        bottom: -6,
                        right: -8,
                        child: GestureDetector(
                          onTap: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 512,
                              maxHeight: 512,
                              imageQuality: 80,
                            );
                            if (image != null) {
                              controller.setEditProfileImage(File(image.path));
                            }
                          },
                          child: Image.asset(
                            Assets.imagesEdit,
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                MyText(
                  text: 'personal_information'.tr,
                  color: kblack2,
                  size: 14,
                  weight: FontWeight.bold,
                  paddingBottom: 15,
                ),
                MyTextField(
                  hint: 'full_name'.tr,
                  controller: controller.editNameController,
                  focusedFilledColor: kpurple1.withOpacity(0.05),
                ),
                // Email (read-only)
                AbsorbPointer(
                  child: MyTextField(
                    hint: 'email_address'.tr,
                    controller: controller.editEmailController,
                    focusedFilledColor: kpurple1.withOpacity(0.05),
                    hintColor: kgrey1.withOpacity(0.7),
                  ),
                ),
                MyText(
                  paddingTop: 15,
                  text: 'more_info'.tr,
                  color: kblack2,
                  size: 14,
                  weight: FontWeight.bold,
                  paddingBottom: 15,
                ),
                // Country Dropdown
                Obx(() => CustomDropDown(
                      hint: 'select_country'.tr,
                      items: controller.countries,
                      selectedValue: controller.selectedCountry.value.isEmpty
                          ? 'select_country'.tr
                          : controller.selectedCountry.value,
                      mBottom: 0,
                      onChanged: (value) {
                        if (value != null && value != 'select_country'.tr) {
                          controller.setCountry(value);
                        }
                      },
                    )),
                SizedBox(height: 15),
                // Date of Birth - Clickable field
                GestureDetector(
                  onTap: () => controller.pickDateOfBirth(context),
                  child: AbsorbPointer(
                    child: MyTextField(
                      hint: 'date_of_birth'.tr,
                      controller: controller.editDobController,
                      focusedFilledColor: kpurple1.withOpacity(0.05),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color: kgrey1,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                // Gender Dropdown
                Obx(() => CustomDropDown(
                      hint: 'select_gender'.tr,
                      items: controller.genders,
                      selectedValue: controller.selectedGender.value.isEmpty
                          ? 'select_gender'.tr
                          : controller.selectedGender.value,
                      mBottom: 0,
                      onChanged: (value) {
                        if (value != null && value != 'select_gender'.tr) {
                          controller.setGender(value);
                        }
                      },
                    )),
              ],
            ),
          ),
          SizedBox(
            height: 15,
          ),
          Obx(() => MyButton(
                onTap: controller.isUpdating.value
                    ? () {}
                    : () async {
                        final success = await controller.updateProfile();
                        if (success) {
                          Navigator.pop(Get.context!);
                        }
                      },
                buttonText:
                    controller.isUpdating.value ? 'updating'.tr : 'update'.tr,
                mBottom: 30,
                mhoriz: 20,
              )),
        ],
      ),
    );
  }
}
