import 'package:get/get.dart';
import 'package:orland_sports/utils/custom_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for managing biometric/security settings
class SecurityController extends GetxController {
  static SecurityController get instance => Get.find<SecurityController>();

  // Observables
  final RxBool isFaceIdEnabled = false.obs;
  final RxBool isBiometricIdEnabled = false.obs;

  static const String _faceIdKey = 'face_id_enabled';
  static const String _biometricIdKey = 'biometric_id_enabled';

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  /// Load saved settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isFaceIdEnabled.value = prefs.getBool(_faceIdKey) ?? false;
    isBiometricIdEnabled.value = prefs.getBool(_biometricIdKey) ?? false;
  }

  /// Toggle Face ID setting
  Future<void> toggleFaceId(bool value) async {
    isFaceIdEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_faceIdKey, value);
    CustomToast.instance.showSuccessToast(
      title: 'face_id'.tr,
      message: value ? 'face_id_enabled'.tr : 'face_id_disabled'.tr,
    );
  }

  /// Toggle Biometric ID setting
  Future<void> toggleBiometricId(bool value) async {
    isBiometricIdEnabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricIdKey, value);
    CustomToast.instance.showSuccessToast(
      title: 'biometric_id'.tr,
      message: value ? 'biometric_id_enabled'.tr : 'biometric_id_disabled'.tr,
    );
  }
}
