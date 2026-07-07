import 'package:get/get.dart';
import 'package:orland_sports/controllers/auth_controller.dart';
import 'package:orland_sports/controllers/OnBoardingController.dart';
import 'package:orland_sports/controllers/court_controller.dart';
import 'package:orland_sports/controllers/explore_controller.dart';
import 'package:orland_sports/controllers/geo_filter_controller.dart';
import 'package:orland_sports/controllers/identity_verification_controller.dart';
import 'package:orland_sports/controllers/language_controller.dart';
import 'package:orland_sports/controllers/maps_controller.dart';
import 'package:orland_sports/controllers/match_controller.dart';
import 'package:orland_sports/controllers/payout_controller.dart';
import 'package:orland_sports/controllers/profile_controller.dart';
import 'package:orland_sports/controllers/referee_auth_controller.dart';
import 'package:orland_sports/controllers/score_controller.dart';
import 'package:orland_sports/controllers/sport_controller.dart';
import 'package:orland_sports/controllers/ticket_controller.dart';

class AuthBinding implements Bindings {
  @override
  void dependencies() {
    Get.put<AuthController>(AuthController());
  }
}

class OnboardingBinding implements Bindings {
  @override
  void dependencies() {
    Get.put<POnboardingController>(POnboardingController());
  }
}

class CourtBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CourtController>(() => CourtController());
    Get.lazyPut<SportController>(() => SportController());
  }
}

class MatchBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MatchController>(() => MatchController());
    Get.lazyPut<GeoFilterController>(() => GeoFilterController());
  }
}

class ExploreBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExploreController>(() => ExploreController());
    Get.lazyPut<MapsController>(() => MapsController());
  }
}

class InitialBinding implements Bindings {
  @override
  void dependencies() {
    Get.put<LanguageController>(LanguageController());
    Get.put<POnboardingController>(POnboardingController());
    Get.put<AuthController>(AuthController());
    Get.put<ProfileController>(ProfileController());
    Get.put<RefereeAuthController>(RefereeAuthController());
    Get.put<IdentityVerificationController>(IdentityVerificationController());

    // Match and Ticket controllers (Lazy with fenix:true for global availability)
    Get.lazyPut<MatchController>(() => MatchController(), fenix: true);
    Get.lazyPut<TicketController>(() => TicketController(), fenix: true);
  }
}

class RefereeBinding implements Bindings {
  @override
  void dependencies() {
    // Ensure auth controller is available
    if (!Get.isRegistered<RefereeAuthController>()) {
      Get.put<RefereeAuthController>(RefereeAuthController());
    }
    if (!Get.isRegistered<IdentityVerificationController>()) {
      Get.put<IdentityVerificationController>(IdentityVerificationController());
    }
    // Initialize all controllers needed for referee screens
    Get.put<CourtController>(CourtController());
    Get.put<MatchController>(MatchController());
    Get.put<SportController>(SportController());
    Get.put<ScoreController>(ScoreController());
    Get.put<PayoutController>(PayoutController());
  }
}

class PlayerBinding implements Bindings {
  @override
  void dependencies() {
    // Ensure auth controller is available
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController());
    }
    if (!Get.isRegistered<ProfileController>()) {
      Get.put<ProfileController>(ProfileController());
    }
    if (!Get.isRegistered<IdentityVerificationController>()) {
      Get.put<IdentityVerificationController>(IdentityVerificationController());
    }
    // Initialize all controllers needed for player screens
    Get.put<MatchController>(MatchController());
    Get.put<CourtController>(CourtController());
    Get.put<SportController>(SportController());
    Get.put<TicketController>(TicketController());
    Get.put<GeoFilterController>(GeoFilterController());
  }
}
