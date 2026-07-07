import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/Profile/Security.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/notification_settings_controller.dart';

class ReferreNotifictaionss extends StatelessWidget {
  const ReferreNotifictaionss({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationSettingsController());

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'notifications_section'.tr,
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
                Obx(() => SwitchRow(
                      textt: 'general_notifications'.tr,
                      isActive: controller.generalNotifications.value,
                      onChanged: controller.toggleGeneral,
                    )),
                SizedBox(height: 10),
                Obx(() => SwitchRow(
                      textt: 'events'.tr,
                      isActive: controller.events.value,
                      onChanged: controller.toggleEvents,
                    )),
                SizedBox(height: 10),
                Obx(() => SwitchRow(
                      textt: 'matches_notification'.tr,
                      isActive: controller.matches.value,
                      onChanged: controller.toggleMatches,
                    )),
                SizedBox(height: 10),
                Obx(() => SwitchRow(
                      textt: 'offers'.tr,
                      isActive: controller.offers.value,
                      onChanged: controller.toggleOffers,
                    )),
                SizedBox(height: 10),
                Obx(() => SwitchRow(
                      textt: 'news'.tr,
                      isActive: controller.news.value,
                      onChanged: controller.toggleNews,
                    )),
                SizedBox(height: 10),
                Obx(() => SwitchRow(
                      textt: 'payment'.tr,
                      isActive: controller.payment.value,
                      onChanged: controller.togglePayment,
                    )),
                SizedBox(height: 10),
                Obx(() => SwitchRow(
                      textt: 'vibrate'.tr,
                      isActive: controller.vibrate.value,
                      onChanged: controller.toggleVibrate,
                    )),
                SizedBox(height: 10),
                Obx(() => SwitchRow(
                      textt: 'others'.tr,
                      isActive: controller.others.value,
                      onChanged: controller.toggleOthers,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
