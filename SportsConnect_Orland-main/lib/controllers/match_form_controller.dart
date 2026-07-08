import 'package:get/get.dart';
import 'package:orland_sports/controllers/current_user_mixin.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/court_model.dart';
import 'package:orland_sports/services/club_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Holds the state of the match-creation wizard.
///
/// Single responsibility: keep the configuration the player assembles before
/// creating a match (sport, category, type, mode, date, time window, partner,
/// preferred clubs, court) and expose the derived data the creation flow needs
/// (available courts, sport UUID resolution). It never writes matches.
class MatchFormController extends GetxController with CurrentUserMixin {
  static MatchFormController get instance => Get.find<MatchFormController>();

  final _courtService = CourtService.instance;

  // Loading / error
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  // Courts data
  final RxList<CourtModel> availableCourts = <CourtModel>[].obs;
  final Rx<CourtModel?> selectedCourt = Rx<CourtModel?>(null);

  // Geo-flow: preferred club IDs selected in GeoFilterScreen
  final RxList<String> preferredClubIds = <String>[].obs;

  // Match configuration
  final Rx<MatchType> selectedMatchType = MatchType.oneVsOne.obs;
  final Rx<MatchMode> selectedMatchMode = MatchMode.competitive.obs;

  /// Display name of the selected sport (e.g. 'Pádel', 'Tenis').
  final RxString selectedSport = ''.obs;
  final RxString selectedCategory = 'Masculino'.obs;

  /// sport name → sport UUID, populated dynamically from the `sports` table.
  final RxMap<String, String> sportUUIDMap = <String, String>{}.obs;

  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxString selectedTimeSlot = ''.obs;
  final RxString selectedEndTimeSlot = ''.obs;
  final RxInt matchDuration = 60.obs;

  // 2v2 Partner setup
  final RxBool hasPartner = false.obs;
  final RxString partnerEmail = ''.obs;

  /// Preferred court side (Drive / Revés / Ambos). Empty = not chosen yet.
  final RxString selectedCourtSide = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadSportsFromDb();
    loadAvailableCourts();
  }

  // ==================== SPORTS ====================

  /// Loads all active sports from the `sports` table and builds [sportUUIDMap].
  Future<void> loadSportsFromDb() async {
    try {
      final response = await Supabase.instance.client
          .from('sports')
          .select('id, name')
          .order('name');
      final map = <String, String>{};
      for (final row in response) {
        final id = row['id'] as String? ?? '';
        final name = row['name'] as String? ?? '';
        if (id.isNotEmpty && name.isNotEmpty) map[name] = id;
      }
      sportUUIDMap.assignAll(map);
      if (selectedSport.value.isEmpty && map.isNotEmpty) {
        selectedSport.value = map.keys.first;
      }
    } catch (e) {
      print('⚠️ loadSportsFromDb error: $e');
    }
  }

  /// Strip common diacritics so 'Pádel' == 'Padel' == 'PADEL'.
  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[áàäâã]'), 'a')
      .replaceAll(RegExp(r'[éèëê]'), 'e')
      .replaceAll(RegExp(r'[íìïî]'), 'i')
      .replaceAll(RegExp(r'[óòöôõ]'), 'o')
      .replaceAll(RegExp(r'[úùüû]'), 'u')
      .replaceAll(RegExp(r'[ñ]'), 'n');

  /// Resolve the UUID for [selectedSport], honoring the selected court's sport
  /// list as ground truth. Returns null if it cannot be determined.
  Future<String?> resolveSelectedSportId() async {
    if (sportUUIDMap.isEmpty) {
      await loadSportsFromDb();
    }

    String? actualSportId = sportUUIDMap[selectedSport.value];

    // Fallback 1: case/accent-insensitive match in the cached map.
    if (actualSportId == null && selectedSport.value.isNotEmpty) {
      final normalizedSelected = _normalize(selectedSport.value);
      final entry = sportUUIDMap.entries.toList().firstWhereOrNull(
            (e) => _normalize(e.key) == normalizedSelected,
          );
      actualSportId = entry?.value;
    }

    // Fallback 2: query the DB directly.
    if (actualSportId == null && selectedSport.value.isNotEmpty) {
      try {
        final normalizedSelected = _normalize(selectedSport.value);
        final rows =
            await Supabase.instance.client.from('sports').select('id, name');
        for (final row in rows) {
          final dbName = row['name'] as String? ?? '';
          if (_normalize(dbName) == normalizedSelected) {
            actualSportId = row['id'] as String?;
            if (actualSportId != null) sportUUIDMap[dbName] = actualSportId;
            break;
          }
        }
      } catch (e) {
        print('⚠️ Sport DB fallback error: $e');
      }
    }

    // Court sports override: prefer the UUID from the actual court's sport list.
    final bool isGeoFlow = preferredClubIds.isNotEmpty;
    if (!isGeoFlow && selectedCourt.value != null) {
      final courtSports = selectedCourt.value!.sports;
      if (courtSports != null && courtSports.isNotEmpty) {
        final normalizedSelected = _normalize(selectedSport.value);
        final match = courtSports.firstWhereOrNull(
          (s) => _normalize(s.name) == normalizedSelected,
        );
        actualSportId = match?.id ?? courtSports.first.id;
      }
    }

    return actualSportId;
  }

  // ==================== COURTS ====================

  /// Load available courts for matchmaking
  Future<void> loadAvailableCourts() async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final courts = await _courtService.getActiveCourts();
      availableCourts.assignAll(courts);
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to load courts: $e';
      print('Error loading courts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selectCourt(CourtModel court) {
    selectedCourt.value = court;
  }

  void clearCourtSelection() {
    selectedCourt.value = null;
  }

  // ==================== CONFIGURATION SETTERS ====================

  void setMatchType(MatchType type) {
    selectedMatchType.value = type;
    if (type == MatchType.oneVsOne && selectedCategory.value == 'Mixto') {
      selectedCategory.value = 'Masculino';
    }
  }

  void setMatchMode(MatchMode mode) {
    selectedMatchMode.value = mode;
  }

  void setSelectedDate(DateTime date) {
    selectedDate.value = date;
  }

  void setSelectedTimeSlot(String timeSlot) {
    selectedTimeSlot.value = timeSlot;
  }

  void setSelectedEndTimeSlot(String timeSlot) {
    selectedEndTimeSlot.value = timeSlot;
  }

  /// Set preferred clubs from GeoFilterScreen
  void setPreferredClubs(List<String> ids) {
    preferredClubIds.assignAll(ids);
    // Clear specific court selection — in geo-flow the admin assigns the court
    selectedCourt.value = null;
  }

  /// Reset match configuration
  void resetMatchConfiguration() {
    selectedCourt.value = null;
    preferredClubIds.clear();
    selectedMatchType.value = MatchType.oneVsOne;
    selectedMatchMode.value = MatchMode.competitive;
    selectedDate.value = DateTime.now();
    selectedTimeSlot.value = '';
    selectedEndTimeSlot.value = '';
    selectedSport.value = sportUUIDMap.isNotEmpty ? sportUUIDMap.keys.first : '';
    selectedCategory.value = 'Masculino';
    hasPartner.value = false;
    partnerEmail.value = '';
    selectedCourtSide.value = '';
  }

  /// Get available time slots for a date
  List<String> getAvailableTimeSlots() {
    return [
      '09:00 AM',
      '10:00 AM',
      '11:00 AM',
      '12:00 PM',
      '01:00 PM',
      '02:00 PM',
      '03:00 PM',
      '04:00 PM',
      '05:00 PM',
      '06:00 PM',
    ];
  }
}
