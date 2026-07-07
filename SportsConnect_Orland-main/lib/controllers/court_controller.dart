import 'package:get/get.dart';
import 'package:orland_sports/models/court_model.dart';
import 'package:orland_sports/services/club_service.dart';
import 'package:orland_sports/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Controller for Court management
/// Reduced to follow the new Gig Economy "Uber" model.
class CourtController extends GetxController {
  static CourtController get instance => Get.find<CourtController>();

  // Services
  final _courtService = CourtService.instance;
  final _supabase = Supabase.instance.client;

  // Observables
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;

  // Courts data
  final RxList<CourtModel> allCourts = <CourtModel>[].obs;

  // Selected court for details
  final Rx<CourtModel?> selectedCourt = Rx<CourtModel?>(null);

  // Error handling
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadActiveCourts();
  }

  /// Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ==================== LOADING METHODS ====================

  /// Load all courts
  Future<void> loadAllCourts() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final courts = await _courtService.getAllCourts();
      allCourts.assignAll(courts);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load courts: $e';
      print('Error loading all courts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load active courts only
  Future<void> loadActiveCourts() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final courts = await _courtService.getActiveCourts();
      allCourts.assignAll(courts);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load active courts: $e';
      print('Error loading active courts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh courts
  Future<void> refreshCourts() async {
    try {
      isRefreshing.value = true;
      await loadActiveCourts();
    } finally {
      isRefreshing.value = false;
    }
  }

  // ==================== DETAIL METHODS ====================

  /// Get court by ID
  Future<void> loadCourtDetails(String courtId) async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final court = await _courtService.getCourtById(courtId);
      selectedCourt.value = court;

      if (court == null) {
        hasError.value = true;
        errorMessage.value = 'Court not found';
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load court details: $e';
      print('Error loading court details: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Select a court from list
  void selectCourt(CourtModel court) {
    selectedCourt.value = court;
  }

  /// Clear selection
  void clearSelection() {
    selectedCourt.value = null;
  }

  // ==================== ERROR HANDLING ====================

  /// Clear error state
  void clearError() {
    hasError.value = false;
    errorMessage.value = '';
  }

  /// Show error snackbar
  void showError(String message) {
    CustomToast.instance.showFailureToast(
      title: 'error'.tr,
      message: message,
    );
  }

  /// Show success snackbar
  void showSuccess(String message) {
    CustomToast.instance.showSuccessToast(
      title: 'success_title'.tr,
      message: message,
    );
  }
}
