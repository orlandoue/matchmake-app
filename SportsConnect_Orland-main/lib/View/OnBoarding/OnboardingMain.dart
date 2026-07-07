import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/OnBoarding/chooseLogin.dart';
import 'package:orland_sports/View/Screens/Referee/Auth/choose_login.dart';
import 'package:orland_sports/View/Widgets/myButton.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/OnBoardingController.dart';
import 'package:orland_sports/enums/user_role.dart';

class OnboardingMain extends StatefulWidget {
  const OnboardingMain({super.key});

  @override
  State<OnboardingMain> createState() => _OnboardingMainState();
}

class _OnboardingMainState extends State<OnboardingMain> {
  final POnboardingController controller = Get.put(POnboardingController());

  final PageController pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final steps = controller.activeSteps;
      final index = controller.stepIndex.value;
      final step = steps[index];
      final isLastStep = index == steps.length - 1;

      return Scaffold(
        body: PageView.builder(
          controller: pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => controller.stepIndex.value = i,
          itemCount: steps.length,
          itemBuilder: (_, pageIndex) {
            return Container(
              height: Get.height,
              width: Get.width,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: kpurple1,
                image: DecorationImage(
                  image: AssetImage(step['image']),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  /// Progress Bar
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      backgroundColor: kgrey1,
                      color: kwhite,
                      value: step['progress'],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  /// Content
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MyText(
                          text: step['titleText'],
                          color: kwhite,
                          size: 24,
                          weight: FontWeight.w800,
                        ),
                        MyText(
                          text: step['descriptionText'],
                          color: kwhite,
                          size: 14,
                          weight: FontWeight.w500,
                          paddingBottom: 20,
                        ),

                        /// Primary Button
                        MyButton(
                          buttonText: step['buttonText1'],
                          fillColor: kwhite,
                          fontColor: kpurple1,
                          mBottom: 15,
                          onTap: () {
                            // FINAL NAVIGATION
                            if (isLastStep) {
                              if (controller.selectedRole.value ==
                                  UserRole.referee) {
                                Get.to(() => RefereeChooseLogin());
                              } else {
                                Get.to(() => const ChooseLogin());
                              }
                              return;
                            }

                            pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),

                        /// Secondary Button (Role Selection)
                        if (step['buttonText2'] != null)
                          MyButton(
                            buttonText: step['buttonText2'],
                            fillColor: kwhite,
                            fontColor: kpurple1,
                            mBottom: 15,
                            onTap: () {
                              controller.selectRole(UserRole.referee);
                              pageController.jumpToPage(0);
                            },
                          ),

                        /// Tertiary Button (Club Admin Selection)
                        if (step['buttonText3'] != null)
                          MyButton(
                            buttonText: step['buttonText3'],
                            fillColor: Colors.transparent,
                            fontColor: kwhite,
                            outlineColor: kwhite,
                            mBottom: 40,
                            onTap: () {
                              controller.selectRole(UserRole.clubAdmin);
                              Get.to(() => const ChooseLogin());
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}
