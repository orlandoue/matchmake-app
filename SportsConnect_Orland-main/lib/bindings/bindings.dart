import 'package:get/get.dart';
import 'package:orland_sports/controllers/auth_controller.dart';
import 'package:orland_sports/controllers/OnBoardingController.dart';
import 'package:orland_sports/controllers/court_controller.dart';
import 'package:orland_sports/controllers/explore_controller.dart';
import 'package:orland_sports/controllers/geo_filter_controller.dart';
import 'package:orland_sports/controllers/identity_verification_controller.dart';
import 'package:orland_sports/controllers/language_controller.dart';
import 'package:orland_sports/controllers/maps_controller.dart';
import 'package:orland_sports/controllers/match_form_controller.dart';
import 'package:orland_sports/controllers/match_creation_controller.dart';
import 'package:orland_sports/controllers/player_matches_controller.dart';
import 'package:orland_sports/controllers/referee_match_controller.dart';
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
    Get.lazyPut<MatchFormController>(() => MatchFormController());
    Get.lazyPut<PlayerMatchesController>(() => PlayerMatchesController());
    Get.lazyPut<MatchCreationController>(() => MatchCreationController());
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

    // Ticket controller available globally (needed by match creation)
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
    // Referee screens only need referee-side match logic + supporting data
    Get.put<CourtController>(CourtController());
    Get.put<SportController>(SportController());
    Get.put<ScoreController>(ScoreController());
    Get.put<PayoutController>(PayoutController());
    Get.put<RefereeMatchController>(RefereeMatchController());
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
    // Player screens: form + own matches + creation, plus supporting data
    Get.put<CourtController>(CourtController());
    Get.put<SportController>(SportController());
    Get.put<TicketController>(TicketController());
    Get.put<GeoFilterController>(GeoFilterController());
    Get.put<MatchFormController>(MatchFormController());
    Get.put<PlayerMatchesController>(PlayerMatchesController());
    Get.put<MatchCreationController>(MatchCreationController());
  }
}
