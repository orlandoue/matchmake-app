import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/utils/custom_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orland_sports/bindings/bindings.dart';
import 'package:orland_sports/View/BottomNavBars/BottomNavbar.dart';
import 'package:orland_sports/View/Widgets/ButtonContainer.dart';
import 'package:orland_sports/View/Widgets/DialogBoxes.dart';
import 'package:orland_sports/View/Widgets/MyDropDown.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/View/Widgets/myTextField.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/auth_controller.dart';
import 'package:orland_sports/generated/assets.dart';

class ProfileInfo1 extends StatefulWidget {
  const ProfileInfo1({super.key});

  @override
  State<ProfileInfo1> createState() => _ProfileInfo1State();
}

class _ProfileInfo1State extends State<ProfileInfo1> {
  final authController = Get.find<AuthController>();
  final ImagePicker _picker = ImagePicker();

  // Local state for dropdowns
  String selectedCountry = 'Country';
  String selectedGender = 'Gender';
  String selectedSkillLevel = 'Beginner';
  String selectedPosition = 'Favorite Position';

  final List<String> countries = [
    'Country',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'Spain',
    'Italy',
    'Brazil',
    'Argentina',
    'Mexico',
    'Japan',
    'China',
    'India',
    'Pakistan',
    'South Africa',
    'Nigeria',
    'Egypt',
    'Other',
  ];

  final List<String> genders = ['Gender', 'Male', 'Female', 'Other'];

  final List<String> skillLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Professional',
  ];

  final List<String> positions = [
    'Favorite Position',
    'Goalkeeper',
    'Defender',
    'Midfielder',
    'Forward',
    'Striker',
    'Winger',
    'Center Back',
    'Full Back',
    'Attacking Midfielder',
    'Defensive Midfielder',
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        authController.setProfileImage(File(image.path));
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar2(
        haveBackButton: false,
        title: profileInfo,
        centerTitle: false,
      ),
      backgroundColor: kwhite,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                Row(
                  children: [
                    Obx(
                      () => GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: kgrey2,
                          ),
                          child: authController.selectedProfileImage.value !=
                                  null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.file(
                                    authController.selectedProfileImage.value!,
                                    fit: BoxFit.cover,
                                    width: 80,
                                    height: 80,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      Assets.imagesAddphoto,
                                      width: 19,
                                      height: 17,
                                    ),
                                    MyText(
                                      text: upload,
                                      size: 12,
                                      color: kgrey1,
                                      paddingTop: 4,
                                    )
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    buttonContainer(
                      text: replace,
                      vPadding: 7,
                      hPadding: 12,
                      onTap: _showImageSourceDialog,
                    ),
                    const SizedBox(width: 10),
                    buttonContainer(
                      text: remove,
                      txtColor: kgrey1,
                      bgColor: kwhite,
                      borderColor: kgrey2,
                      vPadding: 7,
                      hPadding: 12,
                      onTap: () {
                        authController.removeProfileImage();
                      },
                    ),
                  ],
                ),
                MyText(
                  text: personalInformation,
                  size: 15,
                  color: kblack2,
                  paddingTop: 12,
                  weight: FontWeight.bold,
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'required_fields'.tr,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                CustomDropDown(
                  hint: country,
                  items: countries,
                  selectedValue: selectedCountry,
                  isRequired: true,
                  onChanged: (value) {
                    setState(() {
                      selectedCountry = value;
                    });
                    authController.profileCountryController.text = value;
                  },
                  mBottom: 20,
                ),
                Obx(
                  () => GestureDetector(
                    onTap: () => authController.pickDateOfBirth(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: kgrey2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          MyText(
                            text:
                                authController.selectedDateOfBirth.value != null
                                    ? authController.formattedDateOfBirth
                                    : '$dateOfBirth *',
                            size: 14,
                            color:
                                authController.selectedDateOfBirth.value != null
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
                CustomDropDown(
                  hint: gender,
                  items: genders,
                  selectedValue: selectedGender,
                  isRequired: true,
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value;
                    });
                    authController.profileGenderController.text = value;
                  },
                ),
                MyText(
                  text: skillsAndMoreInfo,
                  size: 15,
                  color: kblack2,
                  paddingTop: 12,
                  weight: FontWeight.bold,
                ),
                CustomDropDown(
                  hint: skillLevel,
                  items: skillLevels,
                  selectedValue: selectedSkillLevel,
                  mBottom: 0,
                  onChanged: (value) {
                    setState(() {
                      selectedSkillLevel = value;
                    });
                    authController.profileSkillLevelController.text = value;
                  },
                ),
                CustomDropDown(
                  hint: favoritePosition,
                  items: positions,
                  selectedValue: selectedPosition,
                  isRequired: true,
                  onChanged: (value) {
                    setState(() {
                      selectedPosition = value;
                    });
                    authController.profilePositionController.text = value;
                  },
                ),
              ],
            ),
          ),
          Obx(
            () => MyButton(
              onTap: authController.isLoading.value
                  ? () {}
                  : () {
                      // Validate selections
                      if (selectedCountry == 'Country' ||
                          authController.profileDobController.text.isEmpty ||
                          selectedGender == 'Gender' ||
                          selectedPosition == 'Favorite Position') {
                        CustomToast.instance.showWarningToast(
                          title: 'incomplete'.tr,
                          message: 'please_fill_required_fields'.tr,
                        );
                        return;
                      }

                      // Set values to controller
                      authController.profileCountryController.text =
                          selectedCountry;
                      authController.profileGenderController.text =
                          selectedGender;
                      authController.profileSkillLevelController.text =
                          selectedSkillLevel;
                      authController.profilePositionController.text =
                          selectedPosition;

                      authController.completeProfileSetup().then((success) {
                        if (success) {
                          SuccessDialog.showSuccessDialog(
                            ontap: () {
                              Get.offAll(() => BottomNavBar(),
                                  binding: PlayerBinding());
                            },
                            profileSetupComplete,
                            profileUpdatedMessage,
                          );
                        }
                      });
                    },
              buttonText: authController.isLoading.value
                  ? 'please_wait'.tr
                  : 'complete_setup'.tr,
              mhoriz: 20,
              mBottom: 50,
            ),
          ),
        ],
      ),
    );
  }
}
