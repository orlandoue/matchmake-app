import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/utils/custom_toast.dart';
import 'package:orland_sports/utils/validators.dart';
import 'package:url_launcher/url_launcher.dart';

/// Controller for Contact Us form functionality
class ContactController extends GetxController {
  // Text controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final descriptionController = TextEditingController();

  final RxBool isLoading = false.obs;
  final _validationService = ValidationService.instance;

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  /// Clear the form
  void clearForm() {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    descriptionController.clear();
  }

  /// Validate and send inquiry
  Future<void> sendInquiry() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final description = descriptionController.text.trim();

    // Validation
    if (name.isEmpty) {
      CustomToast.instance.showFailureToast(
        title: 'validation_error'.tr,
        message: 'please_enter_full_name'.tr,
      );
      return;
    }

    if (email.isEmpty) {
      CustomToast.instance.showFailureToast(
        title: 'validation_error'.tr,
        message: 'please_enter_email_address'.tr,
      );
      return;
    }

    final emailError = _validationService.emailValidator(email);
    if (emailError != null) {
      CustomToast.instance.showFailureToast(
        title: 'validation_error'.tr,
        message: emailError,
      );
      return;
    }

    if (description.isEmpty) {
      CustomToast.instance.showFailureToast(
        title: 'validation_error'.tr,
        message: 'please_enter_description'.tr,
      );
      return;
    }

    isLoading.value = true;

    try {
      // Construct mailto URI for sending inquiry
      final subject = Uri.encodeComponent('Contact Inquiry from $name');
      final body = Uri.encodeComponent(
        'Name: $name\n'
        'Email: $email\n'
        'Phone: $phone\n\n'
        'Message:\n$description',
      );

      final mailUri = Uri.parse(
        'mailto:support@matchmakeapp.com?subject=$subject&body=$body',
      );

      if (await canLaunchUrl(mailUri)) {
        await launchUrl(mailUri);
        clearForm();
        CustomToast.instance.showSuccessToast(
          title: 'success_title'.tr,
          message: 'opening_email_client'.tr,
        );
      } else {
        CustomToast.instance.showFailureToast(
          title: 'error'.tr,
          message: 'could_not_open_email'.tr,
        );
      }
    } catch (e) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'failed_send_inquiry'.tr,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
