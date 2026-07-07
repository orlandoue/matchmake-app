import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:orland_sports/const/supabase_config.dart';
import 'package:orland_sports/const/supabase_tables.dart';
import 'package:orland_sports/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  // Private constructor
  SupabaseAuthService._privateConstructor();

  // Singleton instance variable
  static SupabaseAuthService? _instance;

  // Getter to access the singleton instance
  static SupabaseAuthService get instance {
    _instance ??= SupabaseAuthService._privateConstructor();
    return _instance!;
  }

  final _supabase = Supabase.instance.client;

  /// Sign up user with email and password (sends OTP token to email)
  Future<AuthResponse?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      CustomToast.instance.showFailureToast(
        title: 'Authentication Error',
        message: e.message,
      );
      return null;
    } catch (e) {
      print("Exception while signing up: $e");
      return null;
    }
  }

  /// Verify OTP token
  Future<AuthResponse?> verifyOtpToken({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );
      return response;
    } on AuthException catch (e) {
      CustomToast.instance.showFailureToast(
        title: 'Verification Error',
        message: e.message,
      );
      return null;
    } catch (e) {
      print("Exception while verifying OTP: $e");
      return null;
    }
  }

  /// Resend OTP code
  Future<bool> resendOtpCode({
    required String email,
  }) async {
    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      return true;
    } on AuthException catch (e) {
      CustomToast.instance.showFailureToast(
        title: 'Resend Error',
        message: e.message,
      );
      return false;
    } catch (e) {
      print("Exception while resending OTP: $e");
      return false;
    }
  }

  /// Sign in user with email and password
  Future<AuthResponse?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      CustomToast.instance.showFailureToast(
        title: 'Authentication Error',
        message: e.message,
      );
      return null;
    } catch (e) {
      print("Exception while signing in: $e");
      return null;
    }
  }

  /// Check if user exists in database
  Future<bool> userExists({required String userId}) async {
    try {
      final response = await _supabase
          .from(SupabaseTables.usersTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print("Exception while checking user existence: $e");
      return false;
    }
  }

  /// Check if business owner user exists in database (deprecated - use userExists)
  @Deprecated('Use userExists instead')
  Future<bool> businessUserExists({required String userId}) async {
    return userExists(userId: userId);
  }

  /// Check if consumer user exists in database
  // Future<bool> consumerUserExists({required String userId}) async {
  //   try {
  //     final response = await _supabase
  //         .from(SupabaseTables.consumerUserTable)
  //         .select()
  //         .eq('id', userId)
  //         .maybeSingle();

  //     return response != null;
  //   } catch (e) {
  //     print("Exception while checking user existence: $e");
  //     return false;
  //   }
  // }

  /// Authenticate with Google account and return the Supabase AuthResponse
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? SupabaseConfig.googleIosClientId
            : null,
        serverClientId: SupabaseConfig.googleWebClientId,
        scopes: ['email', 'profile'],
      );

      // Sign out first to allow account picker to show every time
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        CustomToast.instance.showFailureToast(
          title: 'Google Sign-In Error',
          message: 'Failed to get authentication token from Google',
        );
        return null;
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      return response;
    } on AuthException catch (e) {
      CustomToast.instance.showFailureToast(
        title: 'Authentication Error',
        message: e.message,
      );
      return null;
    } catch (e) {
      debugPrint('Exception while signing in with Google: $e');
      CustomToast.instance.showFailureToast(
        title: 'Google Sign-In Error',
        message: 'Something went wrong. Please try again.',
      );
      return null;
    }
  }

  /// Update user email
  Future<void> updateUserEmail({
    required String newEmail,
    required String password,
  }) async {
    try {
      // First reauthenticate
      await _supabase.auth.signInWithPassword(
        email: _supabase.auth.currentUser?.email ?? '',
        password: password,
      );

      // Then update email
      await _supabase.auth.updateUser(
        UserAttributes(email: newEmail),
      );

      CustomToast.instance.showSuccessToast(
        title: "Email Updated",
        message: "Your email has been updated successfully",
      );
    } on AuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      CustomToast.instance.showFailureToast(
        title: "Error",
        message: "Failed to update email: ${e.toString()}",
      );
    }
  }

  /// Change user password
  Future<void> updateUserPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // First reauthenticate
      await _supabase.auth.signInWithPassword(
        email: _supabase.auth.currentUser?.email ?? '',
        password: currentPassword,
      );

      // Then update password
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      CustomToast.instance.showSuccessToast(
        title: "Success",
        message: "Password updated successfully",
      );
    } on AuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      CustomToast.instance.showFailureToast(
        title: "Error",
        message: "Failed to update password: ${e.toString()}",
      );
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    if (email.isEmpty) {
      CustomToast.instance.showFailureToast(
        title: "Error",
        message: "Please enter your email",
      );
      return;
    }

    try {
      await _supabase.auth.resetPasswordForEmail(email);
      CustomToast.instance.showSuccessToast(
        title: "Success",
        message: "Password reset email sent. Check your inbox.",
      );
    } on AuthException catch (e) {
      CustomToast.instance.showFailureToast(
        title: "Error",
        message: e.message,
      );
    } catch (e) {
      CustomToast.instance.showFailureToast(
        title: "Error",
        message: e.toString(),
      );
    }
  }

  /// Date picker utility
  Future<String?> pickDateOfBirth(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      return DateFormat('yyyy-MM-dd').format(pickedDate);
    }
    return null;
  }

  /// Handle auth errors
  void _handleAuthError(AuthException e) {
    switch (e.message) {
      case 'User not found':
        CustomToast.instance.showFailureToast(
          title: 'Error',
          message: 'User not found',
        );
        break;
      case 'Invalid login credentials':
        CustomToast.instance.showFailureToast(
          title: 'Error',
          message: 'Wrong password',
        );
        break;
      case 'Email not confirmed':
        CustomToast.instance.showFailureToast(
          title: 'Error',
          message: 'Email not verified',
        );
        break;
      case 'Email rate limit exceeded':
        CustomToast.instance.showFailureToast(
          title: 'Error',
          message: 'Too many attempts. Try again later.',
        );
        break;
      default:
        CustomToast.instance.showFailureToast(
          title: 'Error',
          message: e.message,
        );
        break;
    }
  }

  /// Get current user session
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if current user authenticated via email (not Google/social)
  bool get isEmailAuth {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    return user.appMetadata['provider'] == 'email';
  }

  /// Sign out
  Future<void> signOut() async {
    print('🚪 Starting user sign out process...');

    try {
      // Clean up all real-time services and subscriptions
      // RealtimeServiceInitializer.cleanupOnLogout();

      // Sign out from Supabase
      await _supabase.auth.signOut();

      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Error during sign out: $e');

      // Still try to sign out even if cleanup fails
      await _supabase.auth.signOut();
      rethrow;
    }
  }
}
