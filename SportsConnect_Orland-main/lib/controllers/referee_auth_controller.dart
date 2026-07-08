import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/bindings/bindings.dart';
import 'package:orland_sports/View/BottomNavBars/bottom_nav_bar_ref.dart';
import 'package:orland_sports/View/BottomNavBars/BottomNavbar.dart';
import 'package:orland_sports/View/Screens/Referee/Auth/Login/LoginScreen.dart';
import 'package:orland_sports/View/Screens/Users/Auth/Login/LoginScreen.dart';
import 'package:orland_sports/View/Screens/Users/ProfileCompletion/Profileinfo1.dart';
import 'package:orland_sports/controllers/referee_match_controller.dart';
import 'package:orland_sports/enums/user_role.dart';
import 'package:orland_sports/models/user_model.dart';
import 'package:orland_sports/services/player_service.dart';
import 'package:orland_sports/services/supabase_auth.dart';
import 'package:orland_sports/utils/custom_toast.dart';
import 'package:orland_sports/utils/validators.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Controller for Referee Authentication and Profile Management
class RefereeAuthController extends GetxController {
  static RefereeAuthController get instance =>
      Get.find<RefereeAuthController>();

  // Services
  final _authService = SupabaseAuthService.instance;
  final _playerService = PlayerService.instance;
  final _validationService = ValidationService.instance;

  // Observables
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;
  final RxBool rememberMe = true.obs;
  final RxBool agreeToTerms = false.obs;

  // Text Controllers - Sign Up
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Text Controllers - Login
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  // Text Controllers - Forgot Password
  final forgotPasswordEmailController = TextEditingController();

  // Text Controllers - Edit Profile
  final editNameController = TextEditingController();
  final editEmailController = TextEditingController();
  final editPhoneController = TextEditingController();
  final editCountryController = TextEditingController();
  final editDobController = TextEditingController();
  final editGenderController = TextEditingController();

  // Profile Image for edit
  final Rx<File?> editProfileImage = Rx<File?>(null);

  // Date of Birth for edit profile
  final Rx<DateTime?> editDateOfBirth = Rx<DateTime?>(null);

  // Dropdown selections
  final RxString selectedCountry = ''.obs;
  final RxString selectedGender = ''.obs;

  // OTP
  final otpController = TextEditingController();
  final RxInt otpResendTimer = 60.obs;
  Timer? _otpTimer;

  // Temporary storage for signup data
  String? _pendingEmail;
  String? _pendingPassword;
  String? _pendingName;

  // Lists for dropdowns
  final List<String> countries = [
    'Select Country',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'Spain',
    'Italy',
    'Brazil',
    'Argentina',
    'Mexico',
    'Japan',
    'China',
    'India',
    'Pakistan',
    'South Africa',
    'Nigeria',
    'Egypt',
    'Other',
  ];

  final List<String> genders = ['Select Gender', 'Male', 'Female', 'Other'];

  @override
  void onInit() {
    super.onInit();
    _checkAuthStatus();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    loginEmailController.dispose();
    loginPasswordController.dispose();
    forgotPasswordEmailController.dispose();
    editNameController.dispose();
    editEmailController.dispose();
    editPhoneController.dispose();
    editCountryController.dispose();
    editDobController.dispose();
    editGenderController.dispose();
    otpController.dispose();
    _otpTimer?.cancel();
    super.onClose();
  }

  /// Check current auth status on app start
  Future<void> _checkAuthStatus() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        await _loadCurrentUser();
      }
    } catch (e) {
      print('Error checking auth status: $e');
    }
  }

  /// Load current user data
  Future<void> _loadCurrentUser() async {
    try {
      currentUser.value = await _playerService.getCurrentPlayer();
      if (currentUser.value != null) {
        _populateEditForm();
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  /// Populate edit form with current user data
  void _populateEditForm() {
    final user = currentUser.value;
    if (user == null) return;

    editNameController.text = user.name ?? '';
    editEmailController.text = user.email;
    editCountryController.text = user.country ?? '';
    editGenderController.text = user.gender ?? '';

    selectedCountry.value = (user.country != null && user.country!.isNotEmpty)
        ? user.country!
        : 'Select Country';
    selectedGender.value = (user.gender != null && user.gender!.isNotEmpty)
        ? user.gender!
        : 'Select Gender';

    // Parse date of birth if exists
    if (user.dateOfBirth != null && user.dateOfBirth!.isNotEmpty) {
      try {
        editDateOfBirth.value = DateTime.parse(user.dateOfBirth!);
        editDobController.text = formattedDateOfBirth;
      } catch (e) {
        print('Error parsing date of birth: $e');
      }
    }
  }

  /// Get user name
  String get userName => currentUser.value?.name ?? 'Referee';

  /// Get user email
  String get userEmail => currentUser.value?.email ?? '';

  /// Get profile image URL
  String? get profileImageUrl => currentUser.value?.profileImageUrl;

  /// Check if user has profile image
  bool get hasProfileImage =>
      profileImageUrl != null && profileImageUrl!.isNotEmpty;

  /// Validate email
  String? validateEmail(String? value) {
    return _validationService.emailValidator(value);
  }

  /// Validate password
  String? validatePassword(String? value) {
    return _validationService.passwordValidator(value);
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  /// Toggle terms agreement
  void toggleTermsAgreement() {
    agreeToTerms.value = !agreeToTerms.value;
  }

  /// Toggle remember me
  void toggleRememberMe() {
    rememberMe.value = !rememberMe.value;
  }

  /// Sign Up for Referee
  Future<bool> signUp() async {
    if (!agreeToTerms.value) {
      CustomToast.instance.showFailureToast(
        title: 'terms_required'.tr,
        message: 'please_agree_terms'.tr,
      );
      return false;
    }

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    // Validate fields
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      CustomToast.instance.showFailureToast(
        title: 'validation_error'.tr,
        message: 'please_fill_all_fields'.tr,
      );
      return false;
    }

    // Validate email format on frontend
    final emailError = _validationService.emailValidator(email);
    if (emailError != null) {
      CustomToast.instance.showFailureToast(
        title: 'validation_error'.tr,
        message: emailError,
      );
      return false;
    }

    // Validate password strength
    final passwordError = _validationService.validatePassword(password);
    if (passwordError != null) {
      CustomToast.instance.showFailureToast(
        title: 'weak_password'.tr,
        message: passwordError,
      );
      return false;
    }

    if (password != confirmPasswordController.text) {
      CustomToast.instance.showFailureToast(
        title: 'validation_error'.tr,
        message: 'passwords_do_not_match'.tr,
      );
      return false;
    }

    isLoading.value = true;

    try {
      // Store pending data for after OTP verification
      _pendingEmail = email;
      _pendingPassword = password;
      _pendingName = name;

      // Sign up with Supabase (sends OTP email)
      final response = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (response != null && response.user != null) {
        // Start OTP timer
        startOtpTimer();

        CustomToast.instance.showSuccessToast(
          title: 'verification_sent'.tr,
          message: 'check_email_verification'.tr,
        );

        isLoading.value = false;
        return true;
      }

      isLoading.value = false;
      return false;
    } catch (e) {
      print('Sign up error: $e');
      isLoading.value = false;
      CustomToast.instance.showFailureToast(
        title: 'sign_up_failed'.tr,
        message: e.toString(),
      );
      return false;
    }
  }

  /// Start OTP resend timer
  void startOtpTimer() {
    otpResendTimer.value = 60;
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpResendTimer.value > 0) {
        otpResendTimer.value--;
      } else {
        timer.cancel();
      }
    });
  }

  /// Resend OTP
  Future<void> resendOtp() async {
    if (otpResendTimer.value > 0) return;

    if (_pendingEmail == null) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'email_not_found'.tr,
      );
      return;
    }

    isLoading.value = true;

    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: _pendingEmail!,
      );

      startOtpTimer();

      CustomToast.instance.showSuccessToast(
        title: 'code_sent'.tr,
        message: 'verification_code_resent'.tr,
      );
    } catch (e) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'failed_resend_code'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Verify OTP and complete signup (Referee - no profile completion)
  Future<bool> verifyOtp(String otp) async {
    if (_pendingEmail == null) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'email_not_found'.tr,
      );
      return false;
    }

    isLoading.value = true;

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.signup,
        email: _pendingEmail!,
        token: otp,
      );

      if (response.user != null) {
        // Create referee in database (profile complete by default, no extra steps)
        final success = await _playerService.createPlayer(
          id: response.user!.id,
          email: _pendingEmail!,
          name: _pendingName ?? '',
          role: UserRole.referee,
        );

        if (success) {
          // Mark profile as complete for referee (no extra profile completion needed)
          await _playerService.updatePlayerProfile(
            id: response.user!.id,
            isProfileComplete: true,
          );

          // Load user data
          await _loadCurrentUser();

          // Clear pending data
          _clearPendingData();
          _clearSignUpForm();

          CustomToast.instance.showSuccessToast(
            title: 'success_title'.tr,
            message: 'account_created'.tr,
          );

          isLoading.value = false;
          return true;
        }
      }

      isLoading.value = false;
      CustomToast.instance.showFailureToast(
        title: 'verification_failed'.tr,
        message: 'invalid_verification_code'.tr,
      );
      return false;
    } catch (e) {
      print('OTP verification error: $e');
      isLoading.value = false;
      CustomToast.instance.showFailureToast(
        title: 'verification_failed'.tr,
        message: 'invalid_expired_code'.tr,
      );
      return false;
    }
  }

  /// Login
  Future<bool> login() async {
    final email = loginEmailController.text.trim();
    final password = loginPasswordController.text;

    if (email.isEmpty || password.isEmpty) {
      CustomToast.instance.showFailureToast(
        title: 'validation_error'.tr,
        message: 'please_enter_email_password'.tr,
      );
      return false;
    }

    isLoading.value = true;

    try {
      final response = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (response != null && response.user != null) {
        // Load user data and check role from DB
        await _loadCurrentUser();

        // Clear form
        _clearLoginForm();

        CustomToast.instance.showSuccessToast(
          title: 'welcome_back_title'.tr,
          message: 'login_successful'.tr,
        );

        isLoading.value = false;
        return true;
      }

      isLoading.value = false;
      return false;
    } catch (e) {
      print('Login error: $e');
      isLoading.value = false;
      CustomToast.instance.showFailureToast(
        title: 'login_failed'.tr,
        message: 'invalid_email_or_password'.tr,
      );
      return false;
    }
  }

  /// Navigate after successful login based on DB role
  Future<void> navigateAfterLogin() async {
    print('🔐 NAVIGATE AFTER LOGIN - START');
    print('👤 Current User ID: $currentUserId');

    // Check user role from DB and navigate accordingly
    if (currentUser.value?.role != UserRole.referee) {
      // User is a player - navigate to player dashboard
      if (currentUser.value?.isProfileComplete == true) {
        Get.offAll(() => BottomNavBar(), binding: PlayerBinding());
      } else {
        Get.offAll(() => const ProfileInfo1());
      }
      return;
    }

    // Navigate with binding - this will create/initialize controllers
    Get.offAll(
      () => BottomNavBarReferre(),
      binding: RefereeBinding(),
    );

    // Wait for navigation and binding to complete
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      final matchController = Get.find<RefereeMatchController>();
      print('✅ Controllers found after navigation');

      final userId = currentUserId;
      if (userId == null) {
        print('❌ No user ID found!');
        return;
      }

      // Load match data (Gig Economy model - orphan confirmed matches)
      print('📋 Loading referee marketplace and matches...');
      await matchController.loadRefereeAvailableMatches();
      await matchController.loadRefereeScheduledMatches();
      await matchController.loadRefereeAllMatches();

      // Initialize real-time subscriptions for matches
      matchController.initRefereeSubscriptions();
      print('✅ Real-time subscriptions initialized');
      print('🎉 All data loaded successfully!');
    } catch (e) {
      print('❌ Error loading referee data after login: $e');
    }
  }

  /// Sign in with Google (Referee)
  Future<bool> signInWithGoogle() async {
    isLoading.value = true;

    try {
      final response = await _authService.signInWithGoogle();

      if (response != null && response.user != null) {
        final userId = response.user!.id;
        final email = response.user!.email ?? '';
        final name = response.user!.userMetadata?['full_name'] as String? ??
            response.user!.userMetadata?['name'] as String? ??
            '';

        // Check if user already exists in database
        final exists = await _authService.userExists(userId: userId);

        if (!exists) {
          // Create new referee in database
          final created = await _playerService.createPlayer(
            id: userId,
            email: email,
            name: name,
            role: UserRole.referee,
          );

          if (!created) {
            isLoading.value = false;
            CustomToast.instance.showFailureToast(
              title: 'error'.tr,
              message: 'failed_create_referee_profile'.tr,
            );
            return false;
          }

          // Mark profile as complete for referee
          await _playerService.updatePlayerProfile(
            id: userId,
            isProfileComplete: true,
          );
        }

        // Load user data
        await _loadCurrentUser();

        CustomToast.instance.showSuccessToast(
          title: 'success_title'.tr,
          message: 'signed_in_google'.tr,
        );

        isLoading.value = false;
        return true;
      }

      isLoading.value = false;
      return false;
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      isLoading.value = false;
      CustomToast.instance.showFailureToast(
        title: 'google_signin_failed'.tr,
        message: 'something_went_wrong'.tr,
      );
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail() async {
    final email = forgotPasswordEmailController.text.trim();

    if (email.isEmpty) {
      CustomToast.instance.showFailureToast(
        title: 'validation_error'.tr,
        message: 'please_enter_email'.tr,
      );
      return false;
    }

    isLoading.value = true;

    try {
      await _authService.sendPasswordResetEmail(email: email);
      isLoading.value = false;

      // Clear form
      forgotPasswordEmailController.clear();

      CustomToast.instance.showSuccessToast(
        title: 'email_sent'.tr,
        message: 'password_reset_sent'.tr,
      );

      return true;
    } catch (e) {
      isLoading.value = false;
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'failed_send_reset'.tr,
      );
      return false;
    }
  }

  /// Set profile image for editing
  void setEditProfileImage(File? image) {
    editProfileImage.value = image;
  }

  /// Remove edit profile image
  void removeEditProfileImage() {
    editProfileImage.value = null;
  }

  /// Set selected country
  void setCountry(String country) {
    selectedCountry.value = country;
    editCountryController.text = country;
  }

  /// Set selected gender
  void setGender(String gender) {
    selectedGender.value = gender;
    editGenderController.text = gender;
  }

  /// Pick date of birth with themed date picker
  Future<void> pickDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: editDateOfBirth.value ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF6B4EFF),
            scaffoldBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B4EFF),
              ),
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6B4EFF),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      editDateOfBirth.value = picked;
      editDobController.text = formattedDateOfBirth;
    }
  }

  /// Get formatted date of birth string
  String get formattedDateOfBirth {
    if (editDateOfBirth.value == null) return '';
    final dob = editDateOfBirth.value!;
    return '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}';
  }

  /// Get date of birth for database (ISO format)
  String get dateOfBirthForDb {
    if (editDateOfBirth.value == null) return '';
    final dob = editDateOfBirth.value!;
    return '${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}';
  }

  /// Update referee profile
  Future<bool> updateProfile() async {
    final userId = currentUser.value?.id;
    if (userId == null) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'user_not_found'.tr,
      );
      return false;
    }

    isUpdating.value = true;

    try {
      String? imageUrl;

      // Upload new profile image if selected
      if (editProfileImage.value != null) {
        imageUrl = await _playerService.uploadProfileImage(
          userId: userId,
          imageFile: editProfileImage.value!,
        );
      }

      // Update profile
      final success = await _playerService.updatePlayerProfile(
        id: userId,
        name: editNameController.text.trim().isNotEmpty
            ? editNameController.text.trim()
            : null,
        country: selectedCountry.value.isNotEmpty &&
                selectedCountry.value != 'Select Country'
            ? selectedCountry.value
            : null,
        dateOfBirth: dateOfBirthForDb.isNotEmpty ? dateOfBirthForDb : null,
        gender: selectedGender.value.isNotEmpty &&
                selectedGender.value != 'Select Gender'
            ? selectedGender.value
            : null,
        profileImageUrl: imageUrl,
      );

      if (success) {
        // Refresh user data
        await _loadCurrentUser();

        // Clear edit image
        editProfileImage.value = null;

        CustomToast.instance.showSuccessToast(
          title: 'success_title'.tr,
          message: 'profile_updated'.tr,
        );

        isUpdating.value = false;
        return true;
      }

      isUpdating.value = false;
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'failed_update_profile'.tr,
      );
      return false;
    } catch (e) {
      print('Profile update error: $e');
      isUpdating.value = false;
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'failed_update_profile'.tr,
      );
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    isLoading.value = true;

    try {
      // capture role before clearing user
      final UserRole role = currentUser.value?.role ?? UserRole.player;

      await _authService.signOut();
      currentUser.value = null;

      // Clear all forms
      _clearSignUpForm();
      _clearLoginForm();
      _clearPendingData();

      // Navigate to role-specific login screen
      if (role == UserRole.referee) {
        Get.offAll(() => const RefereeLoginScreen());
      } else {
        Get.offAll(() => const LoginScreen());
      }

      CustomToast.instance.showSuccessToast(
        title: 'success_title'.tr,
        message: 'logged_out'.tr,
      );
    } catch (e) {
      print('Sign out error: $e');
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'failed_sign_out'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if user is logged in
  bool get isLoggedIn => Supabase.instance.client.auth.currentUser != null;

  /// Get current user ID
  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  // Private helper methods
  void _clearSignUpForm() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    agreeToTerms.value = false;
  }

  void _clearLoginForm() {
    loginEmailController.clear();
    loginPasswordController.clear();
  }

  void _clearPendingData() {
    _pendingEmail = null;
    _pendingPassword = null;
    _pendingName = null;
    otpController.clear();
    _otpTimer?.cancel();
  }
}
