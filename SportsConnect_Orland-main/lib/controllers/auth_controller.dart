import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/BottomNavBars/BottomNavbar.dart';
import 'package:orland_sports/View/BottomNavBars/bottom_nav_bar_ref.dart';
import 'package:orland_sports/View/OnBoarding/chooseLogin.dart';
import 'package:orland_sports/View/Screens/Users/ProfileCompletion/Profileinfo1.dart';
import 'package:orland_sports/bindings/bindings.dart';
import 'package:orland_sports/enums/user_role.dart';
import 'package:orland_sports/models/user_model.dart';
import 'package:orland_sports/services/player_service.dart';
import 'package:orland_sports/services/supabase_auth.dart';
import 'package:orland_sports/utils/custom_toast.dart';
import 'package:orland_sports/utils/validators.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:orland_sports/services/onesignal_service.dart';
import 'package:orland_sports/club_admin/screens/club_bottom_nav.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find<AuthController>();

  // Services
  final _authService = SupabaseAuthService.instance;
  final _playerService = PlayerService.instance;
  final _validationService = ValidationService.instance;

  // Observables
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
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

  // Text Controllers - Profile
  final profileNameController = TextEditingController();
  final profileCountryController = TextEditingController();
  final profileDobController = TextEditingController();
  final profileGenderController = TextEditingController();
  final profileSkillLevelController = TextEditingController();
  final profilePositionController = TextEditingController();

  // Profile Image
  final Rx<File?> selectedProfileImage = Rx<File?>(null);
  final RxString profileImageUrl = ''.obs;

  // Date of Birth - Rx observable for GetX state management
  final Rx<DateTime?> selectedDateOfBirth = Rx<DateTime?>(null);

  // OTP
  final otpController = TextEditingController();
  final RxInt otpResendTimer = 60.obs;
  Timer? _otpTimer;

  // Form Keys
  final signUpFormKey = GlobalKey<FormState>();
  final loginFormKey = GlobalKey<FormState>();
  final forgotPasswordFormKey = GlobalKey<FormState>();
  final profileFormKey = GlobalKey<FormState>();

  // Temporary storage for signup data
  String? _pendingEmail;
  String? _pendingPassword;
  String? _pendingName;

  @override
  void onInit() {
    super.onInit();
    _checkAuthStatus();
  }

  @override
  void onClose() {
    // Dispose controllers
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    loginEmailController.dispose();
    loginPasswordController.dispose();
    forgotPasswordEmailController.dispose();
    profileNameController.dispose();
    profileCountryController.dispose();
    profileDobController.dispose();
    profileGenderController.dispose();
    profileSkillLevelController.dispose();
    profilePositionController.dispose();
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
      _registerPushToken();
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  /// Registers the device token in Supabase
  Future<void> _registerPushToken() async {
    final userId = currentUser.value?.id;
    if (userId == null) return;
    
    // Slight delay to ensure OS SDK completes token assignment
    await Future.delayed(const Duration(seconds: 2));
    
    final token = OneSignalService.instance.getPlayerId();
    if (token != null && token.isNotEmpty) {
      try {
        await Supabase.instance.client
            .from('users')
            .update({'onesignal_player_id': token})
            .eq('id', userId);
      } catch (e) {
        print('Error syncing onesignal player id: $e');
      }
    }
  }

  /// Public method to refresh user data from database
  Future<void> refreshUser() async {
    await _loadCurrentUser();
  }

  /// Validate sign up form
  String? validateName(String? value) {
    return _validationService.emptyValidator(value);
  }

  String? validateEmail(String? value) {
    return _validationService.emailValidator(value);
  }

  String? validatePassword(String? value) {
    return _validationService.passwordValidator(value);
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'passwords_do_not_match'.tr;
    }
    if (value != passwordController.text) {
      return 'passwords_do_not_match'.tr;
    }
    return null;
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

  /// Sign Up - Step 1: Create account and send OTP
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

      // Sign up with Supabase (sends confirmation email)
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

  /// Verify OTP and complete signup
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
        // Create player in database
        final success = await _playerService.createPlayer(
          id: response.user!.id,
          email: _pendingEmail!,
          name: _pendingName ?? '',
          role: UserRole.player,
        );

        if (success) {
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
        message: 'please_fill_all_fields'.tr,
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
        // Load user data
        await _loadCurrentUser();

        // Clear form
        _clearLoginForm();

        CustomToast.instance.showSuccessToast(
          title: 'success_title'.tr,
          message: 'logged_in_successfully'.tr,
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
        message: e.toString(),
      );
      return false;
    }
  }

  /// Navigate after successful login based on DB role
  void navigateAfterLogin() {
    final role = currentUser.value?.role;
    
    if (role == UserRole.clubAdmin) {
      Get.offAll(() => const ClubBottomNavScreen());
    } else if (role == UserRole.referee) {
      // User is actually a referee - navigate to referee dashboard
      Get.offAll(() => BottomNavBarReferre(), binding: RefereeBinding());
    } else if (currentUser.value?.isProfileComplete == true) {
      Get.offAll(() => BottomNavBar(), binding: PlayerBinding());
    } else {
      Get.offAll(() => const ProfileInfo1());
    }
  }

  /// Sign in with Google
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
          // Create new player in database
          final created = await _playerService.createPlayer(
            id: userId,
            email: email,
            name: name,
            role: UserRole.player,
          );

          if (!created) {
            isLoading.value = false;
            CustomToast.instance.showFailureToast(
              title: 'error'.tr,
              message: 'failed_create_profile'.tr,
            );
            return false;
          }
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

      return true;
    } catch (e) {
      isLoading.value = false;
      return false;
    }
  }

  /// Set profile image
  void setProfileImage(File? image) {
    selectedProfileImage.value = image;
  }

  /// Remove profile image
  void removeProfileImage() {
    selectedProfileImage.value = null;
    profileImageUrl.value = '';
  }

  /// Pick date of birth with themed date picker
  Future<void> pickDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDateOfBirth.value ?? DateTime(2000, 1, 1),
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
      selectedDateOfBirth.value = picked;
      profileDobController.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  /// Get formatted date of birth string
  String get formattedDateOfBirth {
    if (selectedDateOfBirth.value == null) return '';
    final dob = selectedDateOfBirth.value!;
    return '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}';
  }

  /// Complete profile setup
  Future<bool> completeProfileSetup() async {
    final userId = currentUser.value?.id;
    if (userId == null) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'user_not_found'.tr,
      );
      return false;
    }

    // Validate required fields
    if (profileCountryController.text.isEmpty ||
        profileDobController.text.isEmpty ||
        profileGenderController.text.isEmpty ||
        profileSkillLevelController.text.isEmpty ||
        profilePositionController.text.isEmpty) {
      CustomToast.instance.showFailureToast(
        title: 'validation_error'.tr,
        message: 'please_fill_required_fields'.tr,
      );
      return false;
    }

    isLoading.value = true;

    try {
      String? imageUrl;

      // Upload profile image if selected
      if (selectedProfileImage.value != null) {
        imageUrl = await _playerService.uploadProfileImage(
          userId: userId,
          imageFile: selectedProfileImage.value!,
        );
      }

      // Complete profile
      final success = await _playerService.completeProfileSetup(
        id: userId,
        country: profileCountryController.text.trim(),
        dateOfBirth: profileDobController.text.trim(),
        gender: profileGenderController.text.trim(),
        skillLevel: profileSkillLevelController.text.trim(),
        favoritePosition: profilePositionController.text.trim(),
        profileImageUrl: imageUrl,
      );

      if (success) {
        // Reload user data
        await _loadCurrentUser();

        // Clear form
        _clearProfileForm();

        CustomToast.instance.showSuccessToast(
          title: 'success_title'.tr,
          message: 'profile_setup_complete_msg'.tr,
        );

        isLoading.value = false;
        return true;
      }

      isLoading.value = false;
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'failed_profile_setup'.tr,
      );
      return false;
    } catch (e) {
      print('Profile setup error: $e');
      isLoading.value = false;
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'failed_profile_setup'.tr,
      );
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    isLoading.value = true;

    try {
      await _authService.signOut();
      currentUser.value = null;

      // Clear all forms
      _clearSignUpForm();
      _clearLoginForm();
      _clearProfileForm();
      _clearPendingData();

      Get.offAll(() => const ChooseLogin());

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

  /// Check if profile is complete
  bool get isProfileComplete => currentUser.value?.isProfileComplete ?? false;

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

  void _clearProfileForm() {
    profileNameController.clear();
    profileCountryController.clear();
    profileDobController.clear();
    profileGenderController.clear();
    profileSkillLevelController.clear();
    profilePositionController.clear();
    selectedProfileImage.value = null;
    profileImageUrl.value = '';
    selectedDateOfBirth.value = null;
  }

  void _clearPendingData() {
    _pendingEmail = null;
    _pendingPassword = null;
    _pendingName = null;
    otpController.clear();
    _otpTimer?.cancel();
  }
}
