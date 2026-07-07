import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/services/supabase_auth.dart';
import 'package:orland_sports/utils/custom_toast.dart';
import 'package:orland_sports/utils/validators.dart';

class ChangePasswordController extends GetxController {
  static ChangePasswordController get instance =>
      Get.find<ChangePasswordController>();

  final _authService = SupabaseAuthService.instance;
  final _validationService = ValidationService.instance;

  // Text Controllers
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Form Key
  final formKey = GlobalKey<FormState>();

  // Observables
  final RxBool isLoading = false.obs;
  final RxBool isCurrentPasswordVisible = false.obs;
  final RxBool isNewPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;

  // Validators
  String? validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'please_enter_current_password'.tr;
    }
    return null;
  }

  String? validateNewPassword(String? value) {
    return _validationService.passwordValidator(value);
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'please_confirm_new_password'.tr;
    }
    if (value != newPasswordController.text) {
      return 'passwords_do_not_match'.tr;
    }
    return null;
  }

  // Toggles
  void toggleCurrentPasswordVisibility() {
    isCurrentPasswordVisible.value = !isCurrentPasswordVisible.value;
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  /// Change password
  Future<void> changePassword() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      await _authService.updateUserPassword(
        currentPassword: currentPasswordController.text.trim(),
        newPassword: newPasswordController.text.trim(),
      );

      // Clear fields on success
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      Get.back();
    } catch (e) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'failed_change_password'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
