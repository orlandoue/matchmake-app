import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/controllers/auth_controller.dart';
import 'package:orland_sports/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:orland_sports/controllers/player_matches_controller.dart';
import 'package:orland_sports/services/player_service.dart';
import 'package:orland_sports/utils/custom_toast.dart';

class LeagueData {
  final String name;
  final Color color;
  LeagueData(this.name, this.color);
}

class LeagueRanking {
  final LeagueData leagueData;
  /// UUID from the `sports` table — the true identity key for this ranking row.
  final String sportId;
  final String sportName;
  final String category;
  final String tier;
  final int division;
  final int lp;

  LeagueRanking({
    required this.leagueData,
    required this.sportId,
    required this.sportName,
    required this.category,
    required this.tier,
    required this.division,
    required this.lp,
  });

  /// Max stars per division (strict business rule: 4).
  static const int maxStars = 4;

  /// Division progress rendered as filled stars (0–4), translated from [lp]
  /// (0–100). Buckets: 0–24 → 1, 25–49 → 2, 50–74 → 3, 75–100 → 4.
  /// LP is clamped so out-of-range values never break the scale.
  int get currentStars {
    final clamped = lp.clamp(0, 100);
    return (clamped ~/ 25) + 1 > maxStars ? maxStars : (clamped ~/ 25) + 1;
  }
}

/// Controller for managing user profile operations
class ProfileController extends GetxController {
  static ProfileController get instance => Get.find<ProfileController>();

  // Services
  final _playerService = PlayerService.instance;

  // Get current user from AuthController
  AuthController get _authController => AuthController.instance;

  // Observables
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;

  // Profile image for edit
  final Rx<File?> editProfileImage = Rx<File?>(null);

  // Flag to indicate existing photo should be removed
  final RxBool removeExistingPhoto = false.obs;

  // Date of birth for edit profile
  final Rx<DateTime?> editDateOfBirth = Rx<DateTime?>(null);

  // Text Controllers for Edit Profile
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final countryController = TextEditingController();
  final dobController = TextEditingController();
  final genderController = TextEditingController();
  final skillLevelController = TextEditingController();
  final favoritePositionController = TextEditingController();

  // Dropdown selections
  final RxString selectedCountry = ''.obs;
  final RxString selectedGender = ''.obs;
  final RxString selectedSkillLevel = ''.obs;
  final RxString selectedPosition = ''.obs;

  // Lists for dropdowns
  final List<String> countries = [
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

  final List<String> genders = ['Male', 'Female', 'Other'];

  final List<String> skillLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Professional',
  ];

  final List<String> positions = [
    'Goalkeeper',
    'Defender',
    'Midfielder',
    'Forward',
    'Striker',
    'Winger',
    'Center Back',
    'Full Back',
    'Attacking Midfielder',
    'Defensive Midfielder',
  ];

  /// Get current user
  UserModel? get currentUser => _authController.currentUser.value;

  /// Get user name
  String get userName => currentUser?.name ?? 'Guest';

  /// Get user email
  String get userEmail => currentUser?.email ?? '';

  /// Get profile image URL
  String? get profileImageUrl => currentUser?.profileImageUrl;

  /// Check if user has profile image
  bool get hasProfileImage =>
      profileImageUrl != null && profileImageUrl!.isNotEmpty;

  /// Returns the user's rank label for display in the Profile header.
  /// Prioritizes the real DB-backed tier from [userRankings] (set by the SQL
  /// progression trigger). Falls back to win-count only for brand-new users
  /// who have never completed a match.
  String get userRank {
    if (userRankings.isNotEmpty) {
      final r = userRankings.first;
      return '${r.tier} ${r.division}'; // e.g. "Plata 3"
    }
    // Legacy fallback for users without any user_rankings rows yet
    final w = wins;
    if (w >= 50) return 'Diamante';
    if (w >= 30) return 'Platino';
    if (w >= 15) return 'Oro';
    if (w >= 5)  return 'Plata';
    return 'Bronce 3';
  }

  /// Division-progress stars (0–4) for the header rank, aligned with
  /// [userRank] (both read `userRankings.first`). 0 for brand-new users.
  int get userRankStars =>
      userRankings.isNotEmpty ? userRankings.first.currentStars : 0;

  /// Get user ranking position based on wins
  String get rankingPosition =>
      'TOP #${wins > 0 ? (1000 ~/ (wins + 1)) : "N/A"}';

  /// Get games played from match controller
  int get gamesPlayed {
    try {
      final matchController = Get.find<PlayerMatchesController>();
      return matchController.playerMatches
          .where((m) => m.status.value == 'completed')
          .length;
    } catch (_) {
      return 0;
    }
  }

  /// Get wins from match controller
  int get wins {
    try {
      final matchController = Get.find<PlayerMatchesController>();
      final currentUserId = matchController.currentUserId;
      return matchController.playerMatches
          .where((m) =>
              m.status.value == 'completed' && m.winnerId == currentUserId)
          .length;
    } catch (_) {
      return 0;
    }
  }

  /// Get losses from match controller
  int get losses {
    try {
      final matchController = Get.find<PlayerMatchesController>();
      final currentUserId = matchController.currentUserId;
      return matchController.playerMatches
          .where((m) =>
              m.status.value == 'completed' &&
              m.winnerId != null &&
              m.winnerId != currentUserId)
          .length;
    } catch (_) {
      return 0;
    }
  }

  // ==================== LIGAS Y ELO ====================
  final RxList<LeagueRanking> userRankings = <LeagueRanking>[].obs;
  final RxBool isLoadingRankings = false.obs;

  // ── Sport selection ────────────────────────────────────────────────────────
  /// UUID of the sport currently selected in the History pill-selector.
  /// This is the single source of truth — all ranking widgets read from
  /// [currentSportRanking] which is derived from this value.
  final RxString selectedSportId = ''.obs;

  /// Sorted, deduplicated list of sports present in this user's user_rankings.
  /// Derived entirely from [userRankings] — never reads the global `sports` table.
  List<({String id, String name})> get userSports {
    final seen = <String>{};
    return userRankings
        .where((r) => seen.add(r.sportId))
        .map((r) => (id: r.sportId, name: r.sportName))
        .toList();
  }

  /// The [LeagueRanking] row matching [selectedSportId].
  /// Falls back to the first ranking so the UI is never empty.
  LeagueRanking? get currentSportRanking {
    if (userRankings.isEmpty) return null;
    if (selectedSportId.value.isEmpty) return userRankings.first;
    return userRankings.firstWhereOrNull(
              (r) => r.sportId == selectedSportId.value,
            ) ??
        userRankings.first;
  }

  /// Fetch per-sport league rankings (tier / division / lp) for the current user.
  /// Includes sport_id so pills and ranking cards are keyed by UUID, not by name.
  Future<void> fetchRealUserRankings() async {
    final userId = currentUser?.id;
    if (userId == null) return;

    isLoadingRankings.value = true;
    try {
      final response = await Supabase.instance.client
          .from('user_rankings')
          .select('sport_id, category, tier, division, lp, sports:sport_id(name)')
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final List<LeagueRanking> fetched = [];
      for (final row in response) {
        final sportData = row['sports'];

        // GUARD: Skip rankings whose sport no longer exists in the `sports` table.
        // This handles stale user_rankings rows pointing to deleted seed sports
        // (e.g. Pickleball ...0006) without requiring a DB migration.
        if (sportData == null || sportData is! Map) continue;

        final sportId  = (row['sport_id'] as String?) ?? '';
        if (sportId.isEmpty) continue; // orphaned row — skip

        final sportName = (sportData['name'] as String? ?? '').trim();
        if (sportName.isEmpty) continue; // name missing — skip

        final tier     = (row['tier']     as String?) ?? 'Bronce';
        final division = ((row['division'] as num?)?.toInt()) ?? 3;
        final lp       = ((row['lp']       as num?)?.toInt()) ?? 0;
        final category = (row['category'] as String?) ?? 'N/A';

        fetched.add(LeagueRanking(
          leagueData: getLeagueFromTier(tier),
          sportId: sportId,
          sportName: sportName,
          category: category,
          tier: tier,
          division: division,
          lp: lp,
        ));
      }
      userRankings.value = fetched;

      // Auto-select first sport if current selection is no longer valid.
      final ids = fetched.map((r) => r.sportId).toSet();
      if (!ids.contains(selectedSportId.value)) {
        selectedSportId.value = fetched.isNotEmpty ? fetched.first.sportId : '';
      }
    } catch (e) {
      print('Error fetching user rankings: $e');
    } finally {
      isLoadingRankings.value = false;
    }
  }

  /// Public shortcut called after match completion to refresh reactively.
  Future<void> refreshRankings() => fetchRealUserRankings();

  // Keep for backwards compat — remove once all callers use currentSportRanking.
  LeagueRanking? get selectedRanking => currentSportRanking;

  LeagueData getLeagueFromTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'challenger': return LeagueData('Challenger', const Color(0xFF8E24AA));
      case 'diamante':   return LeagueData('Diamante',   const Color(0xFF00BCD4));
      case 'platino':    return LeagueData('Platino',    const Color(0xFF78909C)); // ← previously missing!
      case 'oro':        return LeagueData('Oro',        const Color(0xFFFFD700));
      case 'plata':      return LeagueData('Plata',      const Color(0xFFC0C0C0));
      default:           return LeagueData('Bronce',     const Color(0xFFCD7F32));
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initializeEditProfile();
    fetchRealUserRankings();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    countryController.dispose();
    dobController.dispose();
    genderController.dispose();
    skillLevelController.dispose();
    favoritePositionController.dispose();
    super.onClose();
  }

  /// Initialize edit profile with current user data
  void _initializeEditProfile() {
    if (currentUser != null) {
      _populateEditForm();
    }

    // Listen to currentUser changes
    ever(_authController.currentUser, (user) {
      if (user != null) {
        _populateEditForm();
      }
    });
  }

  /// Populate edit form with current user data
  void _populateEditForm() {
    final user = currentUser;
    if (user == null) return;

    nameController.text = user.name ?? '';
    emailController.text = user.email;
    countryController.text = user.country ?? '';
    genderController.text = user.gender ?? '';
    skillLevelController.text = user.skillLevel ?? '';
    favoritePositionController.text = user.favoritePosition ?? '';

    selectedCountry.value = user.country ?? '';
    selectedGender.value = user.gender ?? '';
    selectedSkillLevel.value = user.skillLevel ?? 'Beginner';
    selectedPosition.value = user.favoritePosition ?? '';

    // Parse date of birth if exists
    if (user.dateOfBirth != null && user.dateOfBirth!.isNotEmpty) {
      try {
        editDateOfBirth.value = DateTime.parse(user.dateOfBirth!);
        dobController.text = formattedDateOfBirth;
      } catch (e) {
        print('Error parsing date of birth: $e');
      }
    }
  }

  /// Reload user data
  Future<void> refreshUserData() async {
    isLoading.value = true;
    try {
      final user = await _playerService.getCurrentPlayer();
      if (user != null) {
        _authController.currentUser.value = user;
        _populateEditForm();
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Set profile image for editing
  void setEditProfileImage(File? image) {
    editProfileImage.value = image;
    removeExistingPhoto.value = false;
  }

  /// Remove edit profile image (both local and existing)
  void removeEditProfileImage() {
    editProfileImage.value = null;
    removeExistingPhoto.value = true;
  }

  /// Set selected country
  void setCountry(String country) {
    selectedCountry.value = country;
    countryController.text = country;
  }

  /// Set selected gender
  void setGender(String gender) {
    selectedGender.value = gender;
    genderController.text = gender;
  }

  /// Set selected skill level
  void setSkillLevel(String level) {
    selectedSkillLevel.value = level;
    skillLevelController.text = level;
  }

  /// Set selected position
  void setPosition(String position) {
    selectedPosition.value = position;
    favoritePositionController.text = position;
  }

  /// Pick date of birth with themed date picker
  Future<void> pickDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: editDateOfBirth.value ?? DateTime(2000, 1, 1),
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
      dobController.text = formattedDateOfBirth;
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

  /// Update user profile
  Future<bool> updateProfile() async {
    final userId = currentUser?.id;
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
        name: nameController.text.trim().isNotEmpty
            ? nameController.text.trim()
            : null,
        country:
            selectedCountry.value.isNotEmpty ? selectedCountry.value : null,
        dateOfBirth: dateOfBirthForDb.isNotEmpty ? dateOfBirthForDb : null,
        gender: selectedGender.value.isNotEmpty ? selectedGender.value : null,
        skillLevel: selectedSkillLevel.value.isNotEmpty
            ? selectedSkillLevel.value
            : null,
        favoritePosition:
            selectedPosition.value.isNotEmpty ? selectedPosition.value : null,
        profileImageUrl: imageUrl ?? (removeExistingPhoto.value ? '' : null),
      );

      if (success) {
        // Refresh user data
        await refreshUserData();

        // Clear edit image
        editProfileImage.value = null;
        removeExistingPhoto.value = false;

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

  /// Sign out user
  Future<void> signOut() async {
    await _authController.signOut();
  }
}
