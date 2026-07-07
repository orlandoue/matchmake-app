import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/custom_popup.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/const/app_fonts.dart';
import 'package:orland_sports/controllers/notification_controller.dart';
import 'package:orland_sports/generated/assets.dart';

class Notifications extends StatelessWidget {
  const Notifications({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationController());

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
          title: 'notifications'.tr,
          haveBackButton: true,
          centerTitle: false,
          actions: [
            CustomPopupMenuButton(
              options: [
                CustomMenuOption(
                  title: 'mark_all_as_read'.tr,
                  onTap: () => controller.markAllAsRead(),
                ),
              ],
              iconPath: Assets.imagesMore,
              iconHeight: 16,
              iconWidth: 4.3,
            ),
          ]),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: kpurple1),
          );
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: kgrey1),
                const SizedBox(height: 16),
                MyText(
                  text: 'no_notifications_yet'.tr,
                  size: 16,
                  color: kgrey1,
                  weight: FontWeight.w500,
                ),
                const SizedBox(height: 8),
                MyText(
                  text: 'updates_here_text'.tr,
                  size: 14,
                  color: kgrey1,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadNotifications,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              return Obx(() => GestureDetector(
                    onTap: () {
                      if (!notification.isRead.value) {
                        controller.markAsRead(notification.id);
                      }
                    },
                    child: Container(
                      color: notification.isRead.value
                          ? kwhite
                          : kpurple1.withOpacity(0.03),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: kpurple1.withOpacity(0.1),
                            child: Icon(Icons.notifications,
                                color: kpurple1, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  overflow: TextOverflow.ellipsis,
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: notification.title,
                                        style: TextStyle(
                                          color: kblack,
                                          fontSize: 15,
                                          fontFamily: AppFonts.boston,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' ${notification.message}',
                                        style: TextStyle(
                                          color: kblack2,
                                          fontSize: 14,
                                          fontFamily: AppFonts.boston,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                MyText(
                                  text: notification.timeAgo,
                                  size: 12,
                                  color: kgrey1,
                                ),
                              ],
                            ),
                          ),
                          if (!notification.isRead.value)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: kpurple1,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ));
            },
          ),
        );
      }),
    );
  }
}
