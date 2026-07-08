import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/Profile/ChangePassword.dart';
import 'package:orland_sports/View/Screens/Users/Profile/Security.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/security_controller.dart';
import 'package:orland_sports/services/supabase_auth.dart';

class ReferreSecurity extends StatelessWidget {
  const ReferreSecurity({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SecurityController());

    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'security'.tr,
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
                      textt: 'face_id'.tr,
                      isActive: controller.isFaceIdEnabled.value,
                      onChanged: controller.toggleFaceId,
                    )),
                SizedBox(
                  height: 10,
                ),
                Obx(() => SwitchRow(
                      textt: 'biometric_id'.tr,
                      isActive: controller.isBiometricIdEnabled.value,
                      onChanged: controller.toggleBiometricId,
                    )),
                SizedBox(
                  height: 50,
                ),
                if (SupabaseAuthService.instance.isEmailAuth)
                  MyButton(
                    onTap: () {
                      Get.to(() => ChangePassword());
                    },
                    buttonText: 'change_password'.tr,
                    outlineColor: kpurple1,
                    fillColor: kwhite,
                    fontColor: kpurple1,
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
