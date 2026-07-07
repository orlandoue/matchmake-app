import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/myAppBar.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/policy_controller.dart';

class PrivacyPolicy extends StatefulWidget {
  const PrivacyPolicy({super.key});

  @override
  State<PrivacyPolicy> createState() => _PrivacyPolicyState();
}

class _PrivacyPolicyState extends State<PrivacyPolicy> {
  static const _controllerTag = 'user_privacy_policy_controller';
  late final PolicyController _policyController;

  @override
  void initState() {
    super.initState();
    _policyController = Get.put(
      PolicyController(slug: 'privacy_policy'),
      tag: _controllerTag,
    );
    _policyController.loadPolicy(forceRefresh: true);
  }

  @override
  void dispose() {
    if (Get.isRegistered<PolicyController>(tag: _controllerTag)) {
      Get.delete<PolicyController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kwhite,
      appBar: simpleAppBar2(
        title: 'privacy_policy_title'.tr,
        haveBackButton: true,
        centerTitle: false,
      ),
      body: Obx(() {
        if (_policyController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: kpurple1),
          );
        }

        final hasError = _policyController.errorMessage.value.isNotEmpty;
        final policy = _policyController.policy.value;

        if (policy == null || policy.content.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasError ? Icons.error_outline : Icons.policy_outlined,
                  size: 48,
                  color: kgrey1,
                ),
                const SizedBox(height: 12),
                MyText(
                  text: hasError
                      ? _policyController.errorMessage.value
                      : 'no_policy_available'.tr,
                  size: 14,
                  color: kgrey1,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      _policyController.loadPolicy(forceRefresh: true),
                  child: MyText(
                    text: 'retry'.tr,
                    size: 14,
                    color: kpurple1,
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          physics: const BouncingScrollPhysics(),
          children: [
            MyText(
              text: policy.title.isNotEmpty
                  ? policy.title
                  : 'privacy_policy_title'.tr,
              size: 18,
              weight: FontWeight.w700,
              color: kblack2,
              paddingBottom: 12,
            ),
            MyText(
              text: policy.content,
              size: 14,
              weight: FontWeight.w400,
              color: kgrey1,
              textAlign: TextAlign.justify,
            ),
          ],
        );
      }),
    );
  }
}
