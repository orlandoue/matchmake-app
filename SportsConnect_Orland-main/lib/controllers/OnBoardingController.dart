import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/const/App_strings.dart';
import 'package:orland_sports/enums/user_role.dart';
import 'package:orland_sports/generated/assets.dart';

// class POnboardingController extends GetxController {
// static final POnboardingController instance =
//     Get.find<POnboardingController>();

//   RxInt currentStep = 0.obs;

//   void onContinue() {
//     if (currentStep == trainerSteps.length - 1) {
//       // Get.to(() => const GetStarted());
//     } else {
//       currentStep++;
//     }
//   }

//   void onBack() {
//     if (currentStep.value == 0) {
//       Navigator.pop(Get.context!);
//     } else {
//       currentStep--;
//     }
//   }

//   RxInt trainerStep = 0.obs;

//   final List<Map<String, dynamic>> trainerSteps = [
//    {
//       'progress': 0.3,
//       // 'child': const OnBoarding1(),
//       'titleText': chooseYourRole,
//       'descriptionText':
//          rolePrompt,
//       'buttonText1': joinAsPlayer,
//       'buttonText2':joinAsReferee,
//       'image':Assets.imagesOnboarding1
//     },
//     {

//       'progress': 0.6,
//       // 'child': Onboarding2(),
//       'titleText': gatherFriends,
//       'descriptionText':
//           setUpMatch,
//       'buttonText1': gettingStarted,
//       'image':Assets.imagesOnboarding2
//     },
//     {
//       'progress': 0.8,
//       // 'child': Onboarding3(),
//       'titleText': trackYourProgress,
//       'descriptionText':
//          monitorProgress,
//       'buttonText1': 'Next',
//       'image':Assets.imagesOnboarding3
//     },
//     {
//       'progress': 1,
//       // 'child': onBoarding4(),
//       'titleText': competeInRankedMatches,
//       'descriptionText':
//          challengeYourself,
//       'buttonText1': letsGetStarted,
//       'image':Assets.imagesOnboarding4
//     },

//   ];

//   void onNext() {
//     if (trainerStep.value == trainerSteps.length - 1) {
//       // SuccessDialog.showSuccessDialog(cardialog, dialogsubtxt);
//     } else {
//       trainerStep.value++;
//     }
//   }

//   void onPrevious() {
//     if (trainerStep.value == 0) {
//       Navigator.pop(Get.context!);
//     } else {
//       trainerStep.value--;
//     }
//   }
// }

class POnboardingController extends GetxController {
  static final POnboardingController instance =
      Get.find<POnboardingController>();
  RxInt stepIndex = 0.obs;
  Rx<UserRole?> selectedRole = Rx<UserRole?>(null);

  List<Map<String, dynamic>> get activeSteps {
    if (selectedRole.value == UserRole.referee) {
      return [
        {
          'progress': 1.0,
          'titleText': 'welcome_to_referee'.tr,
          'descriptionText': 'referee_onboarding_desc'.tr,
          'buttonText1': letsGetStarted,
          'image': Assets.imagesReferreonboarding,
        }
      ];
    }
    return playerSteps;
  }

  void selectRole(UserRole role) {
    selectedRole.value = role;
    stepIndex.value = 0;
  }

  void nextStep() {
    if (stepIndex.value < activeSteps.length - 1) {
      stepIndex.value++;
    }
  }

  // ------------------ PLAYER STEPS ------------------
  final List<Map<String, dynamic>> playerSteps = [
    {
      'progress': 0.25,
      'titleText': chooseYourRole,
      'descriptionText': rolePrompt,
      'buttonText1': joinAsPlayer,
      'buttonText2': joinAsReferee,
      'buttonText3': 'Únete como Admin de Club',
      'image': Assets.imagesOnboarding1,
    },
    {
      'progress': 0.5,
      'titleText': gatherFriends,
      'descriptionText': setUpMatch,
      'buttonText1': gettingStarted,
      'image': Assets.imagesOnboarding2,
    },
    {
      'progress': 0.75,
      'titleText': trackYourProgress,
      'descriptionText': monitorProgress,
      'buttonText1': 'Siguiente',
      'image': Assets.imagesOnboarding3,
    },
    {
      'progress': 1.0,
      'titleText': competeInRankedMatches,
      'descriptionText': challengeYourself,
      'buttonText1': letsGetStarted,
      'image': Assets.imagesOnboarding4,
    },
  ];

  // ------------------ REFEREE STEP ------------------
  // Referee steps are generated dynamically in activeSteps getter
  // to support .tr localization at runtime
}
