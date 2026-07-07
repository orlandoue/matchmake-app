import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/Profile/ChangePassword.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/security_controller.dart';
import 'package:orland_sports/services/supabase_auth.dart';

class Security extends StatelessWidget {
  const Security({super.key});

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

class SwitchRow extends StatelessWidget {
  final String textt;
  final bool? isActive;
  final ValueChanged<bool>? onChanged;
  const SwitchRow({
    super.key,
    required this.textt,
    this.isActive,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        MyText(
          text: textt,
          size: 16,
          color: kblack,
          weight: FontWeight.w500,
        ),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: isActive ?? false,
            onChanged: onChanged ?? (_) {},
            inactiveTrackColor: kgrey1.withOpacity(0.3),
            trackOutlineColor: WidgetStateColor.transparent,
            inactiveThumbColor: kwhite,
            activeTrackColor: kpurple1,
          ),
        ),
      ],
    );
  }
}
