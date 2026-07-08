import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Referee/Profile/EditProfile.dart';
import 'package:orland_sports/View/Screens/Referee/Profile/Help/Help.dart';
import 'package:orland_sports/View/Screens/Referee/Profile/Notifications.dart';
import 'package:orland_sports/View/Screens/Referee/Profile/PrivacyPolicy.dart';
import 'package:orland_sports/View/Screens/Referee/Profile/Security.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/identity_verification_controller.dart';
import 'package:orland_sports/controllers/referee_auth_controller.dart';
import 'package:orland_sports/generated/assets.dart';
import 'package:orland_sports/View/Screens/Referee/IdentityVerification/VerifyIdentity.dart';

class ReferreProfile extends StatelessWidget {
  const ReferreProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RefereeAuthController>();
    final verificationController = Get.find<IdentityVerificationController>();

    // Load verification status
    final userId = controller.currentUserId;
    if (userId != null) {
      verificationController.loadVerificationStatus(userId);
    }

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'profile'.tr,
        haveBackButton: false,
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
                RefereeImageStack(controller: controller),
                Obx(() => MyText(
                      text: controller.userName,
                      color: kblack2,
                      size: 16,
                      weight: FontWeight.bold,
                      textAlign: TextAlign.center,
                      paddingBottom: 5,
                      paddingTop: 8,
                    )),
                SizedBox(
                  height: 20,
                ),
                MyText(
                  text: 'profile'.tr,
                  color: kgrey1,
                  size: 14,
                  weight: FontWeight.bold,
                  paddingRight: 6,
                  paddingBottom: 15,
                ),
                ReferreProfileRow(
                  title: 'edit_profile'.tr,
                  icon: Assets.imagesProfile,
                  ontap: () {
                    Get.to(() => ReferreEditProfile());
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                ReferreProfileRow(
                  title: 'identity_verification'.tr,
                  icon: Assets.imagesSafety,
                  ontap: () {
                    Get.bottomSheet(ReferreVerifyIdentity(),
                        isScrollControlled: true);
                  },
                  trailing: Obx(() {
                    final vc = Get.find<IdentityVerificationController>();
                    final status = vc.verificationStatus;
                    if (status == 'verified') {
                      return Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('verified'.tr,
                            style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      );
                    } else if (status == 'pending') {
                      return Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('pending'.tr,
                            style: TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      );
                    }
                    return SizedBox.shrink();
                  }),
                ),
                SizedBox(
                  height: 20,
                ),
                ReferreProfileRow(
                  title: 'security'.tr,
                  icon: Assets.imagesSafety,
                  ontap: () {
                    Get.to(() => ReferreSecurity());
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                MyText(
                  // text: 'Payment & Notifications',
                  text: 'notifications_section'.tr,

                  color: kgrey1,
                  size: 14,
                  weight: FontWeight.bold,
                  paddingRight: 6,
                  paddingBottom: 15,
                ),
                // ReferreProfileRow(
                //   title: 'Payment Method',
                //   icon: Assets.imagesPayment,
                //   ontap: () {
                //     Get.to(() => PaymentMethod(
                //           title: 'Add Payment Option',
                //           hasButton: false,
                //         ));
                //   },
                // ),
                SizedBox(
                  height: 20,
                ),
                ReferreProfileRow(
                  title: 'notification'.tr,
                  icon: Assets.imagesNotifications,
                  ontap: () {
                    Get.to(() => ReferreNotifictaionss());
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                MyText(
                  text: 'other_section'.tr,
                  color: kgrey1,
                  size: 14,
                  weight: FontWeight.bold,
                  paddingRight: 6,
                  paddingBottom: 15,
                ),
                ReferreProfileRow(
                  title: 'privacy_policy'.tr,
                  icon: Assets.imagesPrivacy,
                  ontap: () {
                    Get.to(() => ReferrePrivacyPolicy());
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                ReferreProfileRow(
                  title: 'help_center'.tr,
                  icon: Assets.imagesHelp,
                  ontap: () {
                    Get.to(() => ReferreHelpCenter());
                  },
                ),
                SizedBox(
                  height: 40,
                ),
                Obx(() => ReferreProfileRow(
                      title: controller.isLoading.value
                          ? 'logging_out'.tr
                          : 'logout'.tr,
                      titleColor: kred,
                      icon: Assets.imagesLogout,
                      ontap: controller.isLoading.value
                          ? () {}
                          : () => controller.signOut(),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//////////////////////////////
class RefereeImageStack extends StatelessWidget {
  final RefereeAuthController controller;

  const RefereeImageStack({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Obx(() {
            final hasImage = controller.hasProfileImage;
            final imageUrl = controller.profileImageUrl;

            if (hasImage && imageUrl != null) {
              return Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CommonImageView(
                    url: imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            } else {
              return Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: kgrey2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person,
                  color: kgrey1,
                  size: 40,
                ),
              );
            }
          }),
          Positioned(
            bottom: -6,
            right: -8,
            child: GestureDetector(
              onTap: () {
                Get.to(() => ReferreEditProfile());
              },
              child: Image.asset(
                Assets.imagesEdit,
                width: 24,
                height: 24,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ReferreProfileRow extends StatelessWidget {
  final String title;
  final String icon;
  final VoidCallback ontap;
  final Color? titleColor;
  final Widget? trailing;
  const ReferreProfileRow({
    super.key,
    required this.title,
    required this.icon,
    required this.ontap,
    this.titleColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ontap,
      child: Row(
        children: [
          CommonImageView(
            imagePath: icon,
            width: 22,
            height: 22,
          ),
          MyText(
            text: title,
            color: titleColor ?? kblack2,
            size: 15,
            weight: FontWeight.bold,
            paddingLeft: 6,
          ),
          Spacer(),
          if (trailing != null) ...[
            trailing!,
            SizedBox(width: 8),
          ],
          CommonImageView(
            imagePath: Assets.imagesArrowright,
            width: 22,
            height: 22,
          ),
        ],
      ),
    );
  }
}
