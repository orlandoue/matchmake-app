import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/bindings/bindings.dart';
import 'package:orland_sports/View/BottomNavBars/bottom_nav_bar_ref.dart';
import 'package:orland_sports/View/BottomNavBars/BottomNavbar.dart';
import 'package:orland_sports/View/OnBoarding/OnboardingMain.dart';
import 'package:orland_sports/View/Screens/Users/ProfileCompletion/Profileinfo1.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/controllers/auth_controller.dart';
import 'package:orland_sports/controllers/referee_auth_controller.dart';
import 'package:orland_sports/enums/user_role.dart';
import 'package:orland_sports/services/player_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../generated/assets.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  Color _backgroundColor = kwhite;
  Color imageColor = kpurple1;

  @override
  void initState() {
    super.initState();
    _startSplashSequence();
  }

  void _startSplashSequence() {
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _backgroundColor = kpurple1;
        imageColor = kwhite;
      });

      Future.delayed(const Duration(seconds: 2), () {
        _checkAuthAndNavigate();
      });
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // User is logged in, check user role and profile completion
      try {
        // Get user data to check role
        final playerService = PlayerService.instance;
        final userData = await playerService.getCurrentPlayer();

        if (userData != null) {
          if (userData.role == UserRole.referee) {
            // Referee user - use RefereeBinding to properly initialize controllers
            await Future.delayed(const Duration(milliseconds: 500));
            Get.offAll(
              () => BottomNavBarReferre(),
              binding: RefereeBinding(),
            );
          } else {
            // Player user - check profile completion
            final authController = Get.find<AuthController>();
            await Future.delayed(const Duration(milliseconds: 500));

            if (authController.currentUser.value != null) {
              if (authController.currentUser.value!.isProfileComplete) {
                // Profile complete, go to player home with PlayerBinding
                Get.offAll(
                  () => BottomNavBar(),
                  binding: PlayerBinding(),
                );
              } else {
                // Profile incomplete, go to profile setup
                Get.offAll(() => const ProfileInfo1());
              }
            } else {
              // User data not found, go to onboarding
              Get.offAll(() => const OnboardingMain());
            }
          }
        } else {
          // User data not found, go to onboarding
          Get.offAll(() => const OnboardingMain());
        }
      } catch (e) {
        print('Error checking auth: $e');
        Get.offAll(() => const OnboardingMain());
      }
    } else {
      // No session, go to onboarding
      Get.offAll(() => const OnboardingMain());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Image.asset(
              Assets.imagesLogo,
              width: 317,
              height: 121.5,
              color: imageColor,
            ),
          ),
        ],
      ),
    );
  }
}
