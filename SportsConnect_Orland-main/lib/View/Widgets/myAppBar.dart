import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/Home/Notifications.dart';
import 'package:orland_sports/View/Screens/Users/Store/buy_tickets_screen.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/profile_controller.dart';
import 'package:orland_sports/controllers/referee_auth_controller.dart';
import 'package:orland_sports/controllers/ticket_controller.dart';
import 'package:orland_sports/generated/assets.dart';

AppBar simpleAppBar2({
  String? title,
  double? size,
  VoidCallback? onBackIconTap,
  Color? bgColor,
  Color? contentColor,
  bool haveBackButton = true,
  bool centerTitle = false,
  List<Widget>? actions,
}) {
  return AppBar(
    backgroundColor: bgColor ?? kwhite,
    surfaceTintColor: kwhite,
    centerTitle: centerTitle,
    iconTheme: IconThemeData(
      color: Colors.transparent,
    ),
    leadingWidth: haveBackButton ? 35 : 0,
    leading: haveBackButton
        ? Builder(
            builder: (context) => GestureDetector(
              onTap: onBackIconTap ?? () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Image.asset(
                  Assets.imagesBackicon,
                  height: 38,
                  width: 38,
                ),
              ),
            ),
          )
        : null,
    title: MyText(
      text: title ?? '',
      size: size ?? 20,
      weight: FontWeight.w700,
      color: contentColor ?? kblack2,
    ),
    actions: actions,
  );
}
////////////////////////////////////////

class HomeAppbarWidget extends StatelessWidget {
  final Color? bgColor, textsColor;
  final bool? isReferre;
  const HomeAppbarWidget({
    super.key,
    this.bgColor,
    this.textsColor,
    this.isReferre = false,
  });

  @override
  Widget build(BuildContext context) {
    // Use different controller based on user type
    final bool isRefereeUser = isReferre == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Container(
        color: bgColor ?? ktransparent,
        child: Row(
          children: [
            // Profile image
            if (isRefereeUser)
              _buildRefereeProfileImage()
            else
              _buildPlayerProfileImage(),
            SizedBox(
              width: 5,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User name
                if (isRefereeUser)
                  _buildRefereeName(textsColor)
                else
                  _buildPlayerName(textsColor),
              ],
            ),
            Spacer(),
            if (isReferre == false)
              Row(
                children: [
                  ticketcount(),
                  SizedBox(
                    width: 8,
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.to(() => Notifications());
                    },
                    child: Image.asset(
                      Assets.imagesNotifications,
                      width: 15,
                      height: 16,
                      color: textsColor ?? null,
                    ),
                  )
                ],
              ),
            if (isReferre == true)
              GestureDetector(
                onTap: () {
                  Get.to(() => Notifications());
                },
                child: Image.asset(
                  Assets.imagesNotifications,
                  width: 15,
                  height: 16,
                  color: textsColor ?? null,
                ),
              )
          ],
        ),
      ),
    );
  }

  // Player profile image
  Widget _buildPlayerProfileImage() {
    final profileController = Get.find<ProfileController>();
    return Obx(() {
      final hasImage = profileController.hasProfileImage;
      final imageUrl = profileController.profileImageUrl;

      if (hasImage && imageUrl != null) {
        return CommonImageView(
          url: imageUrl,
          width: 48,
          height: 48,
          radius: 10,
        );
      } else {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: kgrey2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.person,
            color: kgrey1,
            size: 28,
          ),
        );
      }
    });
  }

  // Referee profile image
  Widget _buildRefereeProfileImage() {
    final refereeController = Get.find<RefereeAuthController>();
    return Obx(() {
      final hasImage = refereeController.hasProfileImage;
      final imageUrl = refereeController.profileImageUrl;

      if (hasImage && imageUrl != null) {
        return CommonImageView(
          url: imageUrl,
          width: 48,
          height: 48,
          radius: 10,
        );
      } else {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: kgrey2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.person,
            color: kgrey1,
            size: 28,
          ),
        );
      }
    });
  }

  // Player name widget
  Widget _buildPlayerName(Color? textsColor) {
    final profileController = Get.find<ProfileController>();
    return Obx(() => MyText(
          text: 'Hi, ${profileController.userName}!',
          color: textsColor ?? kblack2,
          size: 18,
          weight: FontWeight.bold,
        ));
  }

  // Referee name widget
  Widget _buildRefereeName(Color? textsColor) {
    final refereeController = Get.find<RefereeAuthController>();
    return Obx(() => MyText(
          text: 'Hi, ${refereeController.userName}!',
          color: textsColor ?? kblack2,
          size: 18,
          weight: FontWeight.bold,
        ));
  }
}

class ticketcount extends StatelessWidget {
  const ticketcount({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final singlesBalance = Get.isRegistered<TicketController>()
          ? TicketController.instance.singlesBalance.value
          : 0;
      final doublesBalance = Get.isRegistered<TicketController>()
          ? TicketController.instance.doublesBalance.value
          : 0;
      return Row(
        children: [
          // Singles Ticket
          GestureDetector(
            onTap: () {
              if (Get.isRegistered<TicketController>()) {
                 TicketController.instance.purchasingTicketType.value = 'singles';
              }
              Get.to(() => const BuyTicketsScreen());
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2), 
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: MyText(
                    text: '$singlesBalance', 
                    color: Colors.orange[800], 
                    weight: FontWeight.bold, size: 14
                  ),
                ),
                Positioned(
                  top: -6,
                  left: -8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: kwhite,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.confirmation_num, color: Colors.amber[700], size: 20)
                  )
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Doubles Ticket
          GestureDetector(
            onTap: () {
              if (Get.isRegistered<TicketController>()) {
                 TicketController.instance.purchasingTicketType.value = 'doubles';
              }
              Get.to(() => const BuyTicketsScreen());
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.15), 
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: MyText(
                    text: '$doublesBalance', 
                    color: Colors.blueGrey[800], 
                    weight: FontWeight.bold, size: 14
                  ),
                ),
                Positioned(
                  top: -6,
                  left: -8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: kwhite,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.confirmation_num, color: Colors.blueGrey[600], size: 20)
                  )
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
