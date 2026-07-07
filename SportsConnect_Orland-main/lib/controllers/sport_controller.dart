import 'package:get/get.dart';
import 'package:orland_sports/models/court_model.dart';
import 'package:orland_sports/models/sport_model.dart';
import 'package:orland_sports/services/club_service.dart';
import 'package:orland_sports/services/sport_service.dart';
import 'package:orland_sports/utils/custom_toast.dart';

/// Controller for Sport management
class SportController extends GetxController {
  static SportController get instance => Get.find<SportController>();

  // Services
  final _sportService = SportService.instance;
  final _courtService = CourtService.instance;

  // Observables - Loading states
  final RxBool isLoading = false.obs;
  final RxBool isLoadingCourts = false.obs;
  final RxBool isRefreshing = false.obs;

  // Sports data
  final RxList<SportModel> allSports = <SportModel>[].obs;
  final RxList<SportModel> activeSports = <SportModel>[].obs;

  // Courts filtered by sport
  final RxList<CourtModel> courtsBySport = <CourtModel>[].obs;

  // Selected sport for filtering
  final Rx<SportModel?> selectedSport = Rx<SportModel?>(null);
  final RxList<SportModel> selectedSports = <SportModel>[].obs;

  // Court count per sport
  final RxMap<String, int> courtCountBySport = <String, int>{}.obs;

  // Error handling
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadActiveSports();
  }

  // ==================== LOADING METHODS ====================

  /// Load all sports
  Future<void> loadAllSports() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final sports = await _sportService.getAllSports();
      allSports.assignAll(sports);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load sports: $e';
      print('Error loading all sports: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load active sports only
  Future<void> loadActiveSports() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final sports = await _sportService.getActiveSports();
      activeSports.assignAll(sports);

      // Also load court counts
      await loadCourtCounts();
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load sports: $e';
      print('Error loading active sports: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load court counts for each sport
  Future<void> loadCourtCounts() async {
    try {
      final counts = await _sportService.getCourtCountBySport();
      courtCountBySport.assignAll(counts);
    } catch (e) {
      print('Error loading court counts: $e');
    }
  }

  /// Refresh sports data
  Future<void> refreshSports() async {
    try {
      isRefreshing.value = true;
      await loadActiveSports();
    } finally {
      isRefreshing.value = false;
    }
  }

  // ==================== COURT FILTERING BY SPORT ====================

  /// Load courts for a specific sport
  Future<void> loadCourtsForSport(String sportId) async {
    try {
      isLoadingCourts.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final courts = await _sportService.getCourtsForSport(sportId);
      courtsBySport.assignAll(courts);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load courts: $e';
      print('Error loading courts for sport: $e');
    } finally {
      isLoadingCourts.value = false;
    }
  }

  /// Load courts for multiple selected sports
  Future<void> loadCourtsForSelectedSports() async {
    try {
      isLoadingCourts.value = true;
      hasError.value = false;
      errorMessage.value = '';

      if (selectedSports.isEmpty) {
        // If no sports selected, load all active courts
        final courts = await _courtService.getActiveCourts();
        courtsBySport.assignAll(courts);
      } else {
        final sportIds = selectedSports.map((s) => s.id).toList();
        final courts = await _courtService.getCourtsBySports(sportIds);
        courtsBySport.assignAll(courts);
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load courts: $e';
      print('Error loading courts for selected sports: $e');
    } finally {
      isLoadingCourts.value = false;
    }
  }

  // ==================== SELECTION METHODS ====================

  /// Select a sport for filtering
  void selectSport(SportModel sport) {
    selectedSport.value = sport;
    loadCourtsForSport(sport.id);
  }

  /// Toggle sport selection (for multi-select filtering)
  void toggleSportSelection(SportModel sport, {bool loadCourts = true}) {
    final selectedIndex = selectedSports.indexWhere(
      (selectedSport) => selectedSport.id == sport.id,
    );

    if (selectedIndex >= 0) {
      selectedSports.removeAt(selectedIndex);
    } else {
      selectedSports.add(sport);
    }
    selectedSports.refresh();

    if (loadCourts) {
      loadCourtsForSelectedSports();
    }
  }

  /// Check if a sport is selected
  bool isSportSelected(SportModel sport) {
    return selectedSports.any((selectedSport) => selectedSport.id == sport.id);
  }

  /// Clear sport selection
  void clearSelection({bool loadCourts = false}) {
    selectedSport.value = null;
    selectedSports.clear();
    courtsBySport.clear();

    if (loadCourts) {
      loadCourtsForSelectedSports();
    }
  }

  /// Clear all selected sports
  void clearAllSelectedSports({bool loadCourts = true}) {
    selectedSports.clear();
    selectedSports.refresh();

    if (loadCourts) {
      loadCourtsForSelectedSports();
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Get sport by ID from local list
  SportModel? getSportById(String sportId) {
    try {
      return activeSports.firstWhere((sport) => sport.id == sportId);
    } catch (e) {
      return null;
    }
  }

  /// Get sport by name from local list
  SportModel? getSportByName(String name) {
    try {
      return activeSports.firstWhere(
        (sport) => sport.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get court count for a sport
  int getCourtCount(String sportId) {
    return courtCountBySport[sportId] ?? 0;
  }

  /// Get total number of active sports
  int get totalActiveSports => activeSports.length;

  /// Check if any sports are selected
  bool get hasSelectedSports => selectedSports.isNotEmpty;

  /// Get selected sports count
  int get selectedSportsCount => selectedSports.length;

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
