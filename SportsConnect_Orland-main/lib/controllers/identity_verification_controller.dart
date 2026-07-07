import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orland_sports/models/identity_verification_model.dart';
import 'package:orland_sports/services/identity_verification_service.dart';
import 'package:orland_sports/utils/custom_toast.dart';

class IdentityVerificationController extends GetxController {
  static IdentityVerificationController get instance =>
      Get.find<IdentityVerificationController>();

  final _verificationService = IdentityVerificationService.instance;
  final _picker = ImagePicker();

  // Selected document type
  final RxString selectedDocumentType = ''.obs;

  // Captured images
  final Rx<File?> frontImage = Rx<File?>(null);
  final Rx<File?> backImage = Rx<File?>(null);
  final Rx<File?> selfieImage = Rx<File?>(null);

  // Loading state
  final RxBool isLoading = false.obs;

  // Verification status from DB
  final Rx<IdentityVerificationModel?> verificationRecord =
      Rx<IdentityVerificationModel?>(null);

  // Document type options
  static const List<String> documentTypes = [
    'Passport',
    'ID Card',
    'Driver\'s License',
  ];

  /// Select a document type
  void selectDocumentType(String type) {
    selectedDocumentType.value = type;
  }

  /// Capture front document image using camera
  Future<bool> captureFrontImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        frontImage.value = File(image.path);
        return true;
      }
      return false;
    } catch (e) {
      print('Error capturing front image: $e');
      CustomToast.instance.showFailureToast(
        title: 'camera_error'.tr,
        message: 'failed_capture_image'.tr,
      );
      return false;
    }
  }

  /// Capture back document image using camera
  Future<bool> captureBackImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        backImage.value = File(image.path);
        return true;
      }
      return false;
    } catch (e) {
      print('Error capturing back image: $e');
      CustomToast.instance.showFailureToast(
        title: 'camera_error'.tr,
        message: 'failed_capture_image'.tr,
      );
      return false;
    }
  }

  /// Capture selfie image using front camera
  Future<bool> captureSelfieImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        selfieImage.value = File(image.path);
        return true;
      }
      return false;
    } catch (e) {
      print('Error capturing selfie: $e');
      CustomToast.instance.showFailureToast(
        title: 'camera_error'.tr,
        message: 'failed_capture_selfie'.tr,
      );
      return false;
    }
  }

  /// Load verification status for a user
  Future<void> loadVerificationStatus(String userId) async {
    try {
      verificationRecord.value =
          await _verificationService.getVerification(userId);
    } catch (e) {
      print('Error loading verification status: $e');
    }
  }

  /// Get current verification status
  String get verificationStatus {
    if (verificationRecord.value == null) return 'not_submitted';
    return verificationRecord.value!.status;
  }

  bool get isVerified => verificationRecord.value?.isVerified ?? false;
  bool get isPending => verificationRecord.value?.isPending ?? false;

  /// Upload all documents and complete verification
  Future<bool> submitVerification(String userId) async {
    if (selectedDocumentType.value.isEmpty) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'please_select_document_type'.tr,
      );
      return false;
    }

    if (frontImage.value == null ||
        backImage.value == null ||
        selfieImage.value == null) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'please_capture_all_images'.tr,
      );
      return false;
    }

    isLoading.value = true;

    try {
      // Upload front image
      final frontUrl = await _verificationService.uploadIdentityImage(
        userId: userId,
        imageFile: frontImage.value!,
        imageType: 'front',
      );

      if (frontUrl == null) {
        throw Exception('Failed to upload front document image');
      }

      // Upload back image
      final backUrl = await _verificationService.uploadIdentityImage(
        userId: userId,
        imageFile: backImage.value!,
        imageType: 'back',
      );

      if (backUrl == null) {
        throw Exception('Failed to upload back document image');
      }

      // Upload selfie
      final selfieUrl = await _verificationService.uploadIdentityImage(
        userId: userId,
        imageFile: selfieImage.value!,
        imageType: 'selfie',
      );

      if (selfieUrl == null) {
        throw Exception('Failed to upload selfie image');
      }

      // Insert verification record into separate table
      final success = await _verificationService.submitVerification(
        userId: userId,
        documentType: selectedDocumentType.value,
        frontUrl: frontUrl,
        backUrl: backUrl,
        selfieUrl: selfieUrl,
      );

      if (success) {
        // Reload verification status
        await loadVerificationStatus(userId);
      }

      isLoading.value = false;

      if (success) {
        CustomToast.instance.showSuccessToast(
          title: 'success_title'.tr,
          message: 'identity_verification_completed'.tr,
        );
      }

      return success;
    } catch (e) {
      print('Error submitting verification: $e');
      isLoading.value = false;
      CustomToast.instance.showFailureToast(
        title: 'upload_failed'.tr,
        message: 'failed_upload_documents'.tr,
      );
      return false;
    }
  }

  /// Reset all state for a fresh verification flow
  void reset() {
    selectedDocumentType.value = '';
    frontImage.value = null;
    backImage.value = null;
    selfieImage.value = null;
    isLoading.value = false;
  }
}
