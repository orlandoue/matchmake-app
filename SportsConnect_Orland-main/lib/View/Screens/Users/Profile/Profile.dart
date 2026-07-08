import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/Profile/EditProfile.dart';
import 'package:orland_sports/View/Screens/Users/Profile/Help/Help.dart';
import 'package:orland_sports/View/Screens/Users/Profile/Notifications.dart';
import 'package:orland_sports/View/Screens/Users/Profile/PrivacyPolicy.dart';
import 'package:orland_sports/View/Screens/Users/Profile/QR_Code.dart';
import 'package:orland_sports/View/Screens/Users/Profile/Security.dart';
import 'package:orland_sports/View/Screens/Users/Profile/language.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/ManageMatch.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/View/Widgets/star_rating_row.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/auth_controller.dart';
import 'package:orland_sports/controllers/identity_verification_controller.dart';
import 'package:orland_sports/controllers/profile_controller.dart';
import 'package:orland_sports/generated/assets.dart';
import 'package:orland_sports/View/Screens/Users/IdentityVerification/VerifyIdentity.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    final verificationController = Get.find<IdentityVerificationController>();
    final authController = Get.find<AuthController>();

    // Load verification status
    final userId = authController.currentUserId;
    if (userId != null) {
      verificationController.loadVerificationStatus(userId);
    }

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'my_profile'.tr,
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
                ProfileImageStack(),
                Obx(() {
                  final user = profileController.currentUser;
                  return MyText(
                    text: user?.name ?? 'guest'.tr,
                    color: kblack2,
                    size: 16,
                    weight: FontWeight.bold,
                    textAlign: TextAlign.center,
                    paddingBottom: 5,
                    paddingTop: 8,
                  );
                }),
                Obx(() {
                  // Re-read to trigger reactivity
                  final _ = profileController.currentUser;
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MyText(
                            text: '${'rank'.tr}: ${profileController.userRank}',
                            color: kgrey1,
                            size: 16,
                            weight: FontWeight.w500,
                            paddingRight: 6,
                          ),
                          Image.asset(
                            Assets.imagesTrophyicon,
                            width: 20,
                            height: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      StarRatingRow(
                        stars: profileController.userRankStars,
                        size: 18,
                        gap: 5,
                        emptyColor: kgrey5,
                      ),
                    ],
                  );
                }),
                
                // --- INICIO LIGAS COMPETITIVAS ---
                const SizedBox(height: 25),
                MyText(
                  text: 'Ligas Competitivas',
                  color: kblack2,
                  size: 18,
                  weight: FontWeight.bold,
                  paddingBottom: 15,
                ),
                SizedBox(
                  height: 140, // Increased height for premium cards
                  child: Obx(() {
                    if (profileController.isLoadingRankings.value) {
                      return const Center(
                        child: CircularProgressIndicator(color: kpurple1),
                      );
                    }
                    if (profileController.userRankings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_score_rounded, size: 48, color: kgrey1.withOpacity(0.4)),
                            const SizedBox(height: 8),
                            MyText(
                              text: 'Aún no tienes ligas clasificadas.',
                              color: kgrey1,
                              size: 14,
                              weight: FontWeight.w500,
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: profileController.userRankings.length,
                      itemBuilder: (context, index) {
                        final ranking = profileController.userRankings[index];
                        final division = ranking.division;
                        final league = ranking.leagueData;
                        
                        // Determinar ícono dinámico basado en el nombre del deporte
                        final sportLower = ranking.sportName.toLowerCase();
                        IconData sportIcon = Icons.sports;
                        if (sportLower.contains('teni') || sportLower.contains('tennis')) sportIcon = Icons.sports_tennis;
                        else if (sportLower.contains('padel') || sportLower.contains('pádel')) sportIcon = Icons.sports_tennis;
                        else if (sportLower.contains('futbol') || sportLower.contains('soccer')) sportIcon = Icons.sports_soccer;
                        else if (sportLower.contains('basket')) sportIcon = Icons.sports_basketball;
                        else if (sportLower.contains('volley')) sportIcon = Icons.sports_volleyball;

                        return Container(
                          width: 150,
                          margin: const EdgeInsets.only(right: 16, bottom: 12, top: 4),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                league.color.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: league.color.withOpacity(0.4), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: league.color.withOpacity(0.15),
                                blurRadius: 12,
                                spreadRadius: 0,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(sportIcon, size: 18, color: kgrey1),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: MyText(
                                      text: '${ranking.sportName}',
                                      size: 13,
                                      weight: FontWeight.w600,
                                      color: kgrey1,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              MyText(
                                text: '${league.name.toUpperCase()} $division',
                                size: 16,
                                weight: FontWeight.w900,
                                color: league.color,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 10),
                              StarRatingRow(
                                stars: ranking.currentStars,
                                size: 18,
                                gap: 4,
                                emptyColor: kgrey5,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 10),
                // --- FIN LIGAS COMPETITIVAS ---

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
                ProfileRow(
                  title: 'edit_profile'.tr,
                  icon: Assets.imagesProfile,
                  ontap: () {
                    Get.to(() => EditProfile());
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                ProfileRow(
                  title: 'my_qr_code'.tr,
                  icon: Assets.imagesQrCode,
                  ontap: () {
                    Get.to(() => QRCode());
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                ProfileRow(
                  title: 'manage_matches'.tr,
                  icon: Assets.imagesManagematch,
                  ontap: () {
                    Get.to(() => ManageMatch());
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                ProfileRow(
                  title: 'identity_verification'.tr,
                  icon: Assets.imagesSafety,
                  ontap: () {
                    Get.bottomSheet(VerifyIdentity(), isScrollControlled: true);
                  },
                  trailing: Obx(() {
                    final controller =
                        Get.find<IdentityVerificationController>();
                    final status = controller.verificationStatus;
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
                ProfileRow(
                  title: 'security'.tr,
                  icon: Assets.imagesSafety,
                  ontap: () {
                    Get.to(() => Security());
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
                // ProfileRow(
                //   title: 'Payment Method',
                //   icon: Assets.imagesPayment,
                //   ontap: () {
                //     Get.to(() => PaymentMethod());
                //   },
                // ),
                SizedBox(
                  height: 20,
                ),
                ProfileRow(
                  title: 'notification'.tr,
                  icon: Assets.imagesNotifications,
                  ontap: () {
                    Get.to(() => Notifictaionss());
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
                ProfileRow(
                  title: 'privacy_policy'.tr,
                  icon: Assets.imagesPrivacy,
                  ontap: () {
                    Get.to(() => PrivacyPolicy());
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                ProfileRow(
                  title: 'help_center'.tr,
                  icon: Assets.imagesHelp,
                  ontap: () {
                    Get.to(() => HelpCenter());
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                ProfileRow(
                  title: 'language'.tr,
                  icon: Assets.imagesLanguage,
                  ontap: () {
                    Get.to(() => LanguageProfile());
                  },
                ),
                SizedBox(
                  height: 40,
                ),
                ProfileRow(
                  title: 'logout'.tr,
                  titleColor: kred,
                  icon: Assets.imagesLogout,
                  ontap: () => profileController.signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//////////////////////////////
class ProfileImageStack extends StatelessWidget {
  const ProfileImageStack({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final profileController = Get.find<ProfileController>();
    final authController = Get.find<AuthController>();

    return Center(
      child: Obx(
        () {
          final user = authController.currentUser.value;
          final imageUrl = user?.profileImageUrl;
          final hasImage = imageUrl != null && imageUrl.isNotEmpty;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: kgrey2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: 72,
                          height: 72,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            color: kgrey1,
                            size: 40,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: kgrey1,
                        size: 40,
                      ),
              ),
              Positioned(
                bottom: -6,
                right: -8,
                child: GestureDetector(
                  onTap: () {
                    Get.to(() => EditProfile());
                  },
                  child: Image.asset(
                    Assets.imagesEdit,
                    width: 24,
                    height: 24,
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class ProfileRow extends StatelessWidget {
  final String title;
  final String icon;
  final VoidCallback ontap;
  final Color? titleColor;
  final Widget? trailing;
  const ProfileRow({
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
