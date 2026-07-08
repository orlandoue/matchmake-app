import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orland_sports/View/Widgets/MyDropDown.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/View/Widgets/myTextField.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/profile_controller.dart';

class EditProfile extends StatelessWidget {
  EditProfile({super.key});

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(
      ImageSource source, ProfileController controller) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        controller.setEditProfileImage(File(image.path));
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _showImageSourceDialog(
      BuildContext context, ProfileController controller) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('gallery'.tr),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text('camera'.tr),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, controller);
              },
            ),
            if ((controller.hasProfileImage &&
                    !controller.removeExistingPhoto.value) ||
                controller.editProfileImage.value != null)
              ListTile(
                leading: const Icon(Icons.delete, color: kred),
                title:
                    Text('remove_photo'.tr, style: TextStyle(color: kred)),
                onTap: () {
                  Navigator.pop(context);
                  controller.removeEditProfileImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();

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
                  child: GestureDetector(
                    onTap: () =>
                        _showImageSourceDialog(context, profileController),
                    child: Obx(() {
                      final editImage =
                          profileController.editProfileImage.value;
                      final hasImage = profileController.hasProfileImage &&
                          !profileController.removeExistingPhoto.value;
                      final imageUrl = profileController.profileImageUrl;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: kgrey2,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: editImage != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.file(
                                      editImage,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                    ),
                                  )
                                : hasImage && imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                            Icons.person,
                                            color: kgrey1,
                                            size: 50,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        color: kgrey1,
                                        size: 50,
                                      ),
                          ),
                          Positioned(
                            bottom: -5,
                            right: -5,
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: kpurple1,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: kwhite,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
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
                  hint: 'name'.tr,
                  controller: profileController.nameController,
                  marginBottom: 15,
                ),
                MyTextField(
                  hint: 'email_address'.tr,
                  controller: profileController.emailController,
                  marginBottom: 15,
                  keyboardType: TextInputType.emailAddress,
                ),
                MyText(
                  paddingTop: 15,
                  text: 'more_info'.tr,
                  color: kblack2,
                  size: 14,
                  weight: FontWeight.bold,
                  paddingBottom: 15,
                ),
                Obx(() => CustomDropDown(
                      hint: 'country'.tr,
                      items: ['country'.tr, ...profileController.countries],
                      selectedValue:
                          profileController.selectedCountry.value.isNotEmpty
                              ? profileController.selectedCountry.value
                              : 'country'.tr,
                      mBottom: 0,
                      onChanged: (value) {
                        if (value != 'country'.tr) {
                          profileController.setCountry(value);
                        }
                      },
                    )),
                // Date of Birth Field
                Obx(
                  () => GestureDetector(
                    onTap: () => profileController.pickDateOfBirth(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 16),
                      margin: const EdgeInsets.only(bottom: 16, top: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: kgrey2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          MyText(
                            text:
                                profileController.editDateOfBirth.value != null
                                    ? profileController.formattedDateOfBirth
                                    : 'date_of_birth'.tr,
                            size: 14,
                            color:
                                profileController.editDateOfBirth.value != null
                                    ? kblack2
                                    : kgrey1,
                            weight: FontWeight.w500,
                          ),
                          const Icon(Icons.calendar_today,
                              color: kgrey1, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                Obx(() => CustomDropDown(
                      hint: 'gender'.tr,
                      items: ['gender'.tr, ...profileController.genders],
                      selectedValue:
                          profileController.selectedGender.value.isNotEmpty
                              ? profileController.selectedGender.value
                              : 'gender'.tr,
                      mBottom: 0,
                      onChanged: (value) {
                        if (value != 'gender'.tr) {
                          profileController.setGender(value);
                        }
                      },
                    )),
                MyText(
                  paddingTop: 15,
                  text: 'skills'.tr,
                  color: kblack2,
                  size: 14,
                  weight: FontWeight.bold,
                ),
                Obx(() => CustomDropDown(
                      hint: 'skill_level'.tr,
                      items: profileController.skillLevels,
                      selectedValue:
                          profileController.selectedSkillLevel.value.isNotEmpty
                              ? profileController.selectedSkillLevel.value
                              : 'Beginner',
                      mBottom: 0,
                      onChanged: (value) {
                        profileController.setSkillLevel(value);
                      },
                    )),
                Obx(() => CustomDropDown(
                      hint: 'favorite_position'.tr,
                      items: [
                        'favorite_position'.tr,
                        ...profileController.positions
                      ],
                      selectedValue:
                          profileController.selectedPosition.value.isNotEmpty
                              ? profileController.selectedPosition.value
                              : 'favorite_position'.tr,
                      onChanged: (value) {
                        if (value != 'favorite_position'.tr) {
                          profileController.setPosition(value);
                        }
                      },
                    )),
                SizedBox(height: 15),
                Obx(() => MyButton(
                      onTap: profileController.isUpdating.value
                          ? () {}
                          : () async {
                              final success =
                                  await profileController.updateProfile();
                              if (success) {
                                Navigator.pop(Get.context!);
                              }
                            },
                      buttonText: profileController.isUpdating.value
                          ? 'updating'.tr
                          : 'update'.tr,
                      mBottom: 100,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
