import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Referee/IdentityVerification/ScanDocsFront.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/identity_verification_controller.dart';
import 'package:orland_sports/generated/assets.dart';
import 'package:orland_sports/utils/custom_toast.dart';

class ReferreVerifyIdentity extends StatelessWidget {
  const ReferreVerifyIdentity({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<IdentityVerificationController>();
    controller.reset();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -16,
          left: 0,
          right: 0,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 14),
            height: 20,
            decoration: BoxDecoration(
              color: kwhite.withOpacity(.6),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
        ),
        Container(
          height: Get.height * 0.8,
          decoration: BoxDecoration(
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
                    SizedBox(
                      height: 20,
                    ),
                    MyText(
                      text: identityVerification,
                      color: kpurple1,
                      size: 24,
                      weight: FontWeight.bold,
                      textAlign: TextAlign.center,
                    ),
                    MyText(
                      text: chooseDocumentPrompt,
                      color: kgrey1,
                      size: 14,
                      weight: FontWeight.w500,
                      paddingBottom: 15,
                      textAlign: TextAlign.center,
                    ),
                    _buildDocumentOption(
                      controller: controller,
                      label: passport,
                      icon: Assets.imagesPassport,
                      paddingLeft: 20,
                    ),
                    _buildDocumentOption(
                      controller: controller,
                      label: idCard,
                      icon: Assets.imagesIdcard,
                      paddingLeft: 15,
                    ),
                    _buildDocumentOption(
                      controller: controller,
                      label: driversLicense,
                      icon: Assets.imagesLicense,
                      paddingLeft: 19,
                    ),
                  ],
                ),
              ),
              MyButton(
                onTap: () {
                  if (controller.selectedDocumentType.value.isEmpty) {
                    CustomToast.instance.showWarningToast(
                      title: 'select_document'.tr,
                      message: 'select_document_msg'.tr,
                    );
                    return;
                  }
                  Get.bottomSheet(RefereeScanDocs(), isScrollControlled: true);
                },
                buttonText: 'continue_text'.tr,
                mBottom: 40,
                mhoriz: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentOption({
    required IdentityVerificationController controller,
    required String label,
    required String icon,
    double paddingLeft = 20,
  }) {
    return Obx(
      () {
        final isSelected = controller.selectedDocumentType.value == label;
        return GestureDetector(
          onTap: () => controller.selectDocumentType(label),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? kpurple1.withOpacity(0.05) : kwhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? kpurple1 : kgrey2,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      left: (paddingLeft - 16)
                          .clamp(0, double.infinity)
                          .toDouble(),
                      right: 10),
                  child: CommonImageView(
                    imagePath: icon,
                    height: 15,
                  ),
                ),
                Expanded(
                  child: MyText(
                    text: label,
                    color: kpurple1,
                    size: 14,
                    weight: FontWeight.w500,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: kpurple1, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }
}
