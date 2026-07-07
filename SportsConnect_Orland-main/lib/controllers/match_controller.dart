import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:orland_sports/controllers/auth_controller.dart';
import 'package:orland_sports/controllers/ticket_controller.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/ReviewSummary.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/court_model.dart';
import 'package:orland_sports/models/match_model.dart';
import 'package:orland_sports/services/club_service.dart';
import 'package:orland_sports/services/match_service.dart';
import 'package:orland_sports/controllers/payout_controller.dart';
import 'package:orland_sports/controllers/profile_controller.dart';
import 'package:orland_sports/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Controller for Match management
class MatchController extends GetxController {
  static MatchController get instance => Get.find<MatchController>();

  // Services
  final _matchService = MatchService.instance;
  final _courtService = CourtService.instance;

  // Observables - Loading states
  final RxBool isLoading = false.obs;
  final RxBool isSearchingMatch = false.obs;
  final RxBool isJoiningMatch = false.obs;

  // Per-match loading IDs (to show loader only on the specific card)
  final RxnString acceptingMatchId = RxnString(null);
  final RxnString joiningMatchId = RxnString(null);

  // Courts data
  final RxList<CourtModel> availableCourts = <CourtModel>[].obs;
  final Rx<CourtModel?> selectedCourt = Rx<CourtModel?>(null);

  // Geo-flow: preferred club IDs selected in GeoFilterScreen
  final RxList<String> preferredClubIds = <String>[].obs;

  // Match configuration
  final Rx<MatchType> selectedMatchType = MatchType.oneVsOne.obs;
  final Rx<MatchMode> selectedMatchMode = MatchMode.competitive.obs;
  /// Display name of the selected sport (e.g. 'Pádel', 'Tenis').
  /// Starts empty; the UI populates it once sports are loaded from the DB.
  final RxString selectedSport = ''.obs;
  final RxString selectedCategory = 'Masculino'.obs;

  /// sport name → sport UUID, populated dynamically from the `sports` table.
  /// Never hardcode UUIDs here — they differ between environments.
  final RxMap<String, String> sportUUIDMap = <String, String>{}.obs;

  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxString selectedTimeSlot = ''.obs;
  final RxString selectedEndTimeSlot = ''.obs;
  final RxInt matchDuration = 60.obs;
  
  // 2v2 Partner setup
  final RxBool hasPartner = false.obs;
  final RxString partnerEmail = ''.obs;

  // Match data
  final RxList<MatchModel> playerMatches = <MatchModel>[].obs;
  final RxList<MatchModel> activeMatches = <MatchModel>[].obs;
  final RxList<MatchModel> availableMatchesToJoin = <MatchModel>[].obs;
  final RxList<MatchModel> pendingInvitations = <MatchModel>[].obs;
  final Rx<MatchModel?> currentMatch = Rx<MatchModel?>(null);

  // Referee matches
  final RxList<MatchModel> refereeAvailableMatches = <MatchModel>[].obs;
  final RxList<MatchModel> refereeScheduledMatches = <MatchModel>[].obs;
  final RxList<MatchModel> refereeAllMatches = <MatchModel>[].obs;

  // Declined match IDs (referee chose to skip these)
  final RxSet<String> declinedMatchIds = <String>{}.obs;

  // Recent/completed matches for history tab
  final RxList<MatchModel> refereeCompletedMatches = <MatchModel>[].obs;

  // Invite code
  final RxString inviteCode = ''.obs;

  // Error handling
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  // ==================== HISTORY COMPUTED GETTERS ====================

  /// All completed matches (not cancelled)
  List<MatchModel> get completedMatches =>
      playerMatches.where((m) => m.status == MatchStatus.completed).toList();

  /// Matches the current user won
  List<MatchModel> get wonMatches =>
      completedMatches.where((m) => m.winnerId == currentUserId).toList();

  /// Matches the current user lost
  List<MatchModel> get lostMatches => completedMatches
      .where((m) => m.winnerId != null && m.winnerId != currentUserId)
      .toList();

  /// Completed + cancelled matches for history display
  List<MatchModel> get historyMatches => playerMatches
      .where((m) =>
          m.status == MatchStatus.completed ||
          m.status == MatchStatus.cancelled)
      .toList();

  // Realtime subscription
  RealtimeChannel? _matchSubscription;
  RealtimeChannel? _refereeSubscription;
  RealtimeChannel? _availableMatchesSubscription;

  @override
  void onInit() {
    super.onInit();
    loadSportsFromDb();          // populate sportUUIDMap before any match creation
    loadAvailableCourts();
    _initializeAvailableMatchesSubscription();
  }

  @override
  void onClose() {
    _matchSubscription?.unsubscribe();
    _refereeSubscription?.unsubscribe();
    _availableMatchesSubscription?.unsubscribe();
    super.onClose();
  }

  /// Get current user ID
  String? get currentUserId {
    // Always get from Supabase auth first (works for both players and referees)
    final supabaseUserId = Supabase.instance.client.auth.currentUser?.id;
    if (supabaseUserId != null) {
      return supabaseUserId;
    }

    // Fallback to AuthController if needed
    try {
      return AuthController.instance.currentUser.value?.id;
    } catch (e) {
      return null;
    }
  }

  // ==================== COURT OPERATIONS ====================

  /// Loads all active sports from the `sports` table and builds [sportUUIDMap].
  /// Also seeds [selectedSport] with the first sport name so the matchmaking
  /// UI always has a valid initial selection without hardcoding any name.
  Future<void> loadSportsFromDb() async {
    try {
      final response = await Supabase.instance.client
          .from('sports')
          .select('id, name')
          .order('name');
      final map = <String, String>{};
      for (final row in response) {
        final id   = row['id']   as String? ?? '';
        final name = row['name'] as String? ?? '';
        if (id.isNotEmpty && name.isNotEmpty) map[name] = id;
      }
      sportUUIDMap.assignAll(map);
      // Seed selectedSport with first sport if it isn’t set yet
      if (selectedSport.value.isEmpty && map.isNotEmpty) {
        selectedSport.value = map.keys.first;
      }
    } catch (e) {
      print('⚠️ loadSportsFromDb error: $e');
    }
  }


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

  /// Select a court
  void selectCourt(CourtModel court) {
    selectedCourt.value = court;
  }

  /// Clear court selection
  void clearCourtSelection() {
    selectedCourt.value = null;
  }

  // ==================== MATCH CONFIGURATION ====================

  /// Set match type
  void setMatchType(MatchType type) {
    selectedMatchType.value = type;
    if (type == MatchType.oneVsOne && selectedCategory.value == 'Mixto') {
      selectedCategory.value = 'Masculino';
    }
  }

  /// Set match mode
  void setMatchMode(MatchMode mode) {
    selectedMatchMode.value = mode;
  }

  /// Set selected date
  void setSelectedDate(DateTime date) {
    selectedDate.value = date;
  }

  /// Set selected time slot
  void setSelectedTimeSlot(String timeSlot) {
    selectedTimeSlot.value = timeSlot;
  }

  /// Set selected end time slot
  void setSelectedEndTimeSlot(String timeSlot) {
    selectedEndTimeSlot.value = timeSlot;
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
    inviteCode.value = '';
    currentMatch.value = null;
  }

  /// Set preferred clubs from GeoFilterScreen
  void setPreferredClubs(List<String> ids) {
    preferredClubIds.assignAll(ids);
    // Clear specific court selection — in geo-flow the admin assigns the court
    selectedCourt.value = null;
  }

  // ==================== MATCH OPERATIONS ====================

  /// Load player's active matches (pending, confirmed, etc.)
  Future<void> loadPlayerMatches() async {
    final playerId = currentUserId;
    if (playerId == null) return;

    try {
      isLoading.value = true;
      final matches = await _matchService.getPlayerMatches(playerId);
      playerMatches.assignAll(matches);

      // Refresh active matches specifically
      activeMatches.assignAll(matches
          .where((m) =>
              m.status != MatchStatus.completed &&
              m.status != MatchStatus.cancelled)
          .toList());

      // Find the most relevant active match (e.g., closest to now) to be the current
      if (activeMatches.isNotEmpty) {
        // Sort by date (already sorted from DB, but just to be sure)
        currentMatch.value = activeMatches.first;
        _subscribeToMatch(currentMatch.value!.id);
      } else if (currentMatch.value != null &&
          (currentMatch.value!.status == MatchStatus.completed ||
              currentMatch.value!.status == MatchStatus.cancelled)) {
        // Clear current match if it was completed/cancelled
        currentMatch.value = null;
      }
    } catch (e) {
      print('Error loading player matches: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load available matches that the player can join
  Future<void> loadAvailableMatchesToJoin() async {
    final playerId = currentUserId;
    if (playerId == null) return;

    try {
      isLoading.value = true;
      final matches = await _matchService.getAvailableMatchesForPlayer(playerId);
      availableMatchesToJoin.assignAll(matches);
      
      // Load pending invitations
      final invitations = await _matchService.getPendingInvitations(playerId);
      pendingInvitations.assignAll(invitations);
    } catch (e) {
      print('Error loading available matches: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== MATCH CREATION & JOINING ====================

  /// Create or join a match.
  /// Supports two flows:
  ///  - GEO flow: preferredClubIds set, courtId = null (admin assigns later)
  ///  - Legacy flow: selectedCourt set explicitly
  Future<MatchModel?> createOrJoinMatch() async {
    final bool isGeoFlow = preferredClubIds.isNotEmpty;

    // Validate: must have at least a court OR preferred clubs
    if (!isGeoFlow && selectedCourt.value == null) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'please_select_court'.tr,
      );
      return null;
    }

    if (selectedTimeSlot.value.isEmpty) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'please_select_time_slot'.tr,
      );
      return null;
    }

    final playerId = currentUserId;
    if (playerId == null) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'please_login_continue'.tr,
      );
      return null;
    }

    // Prevent scheduling in the past
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final matchDay = DateTime(selectedDate.value.year, selectedDate.value.month,
        selectedDate.value.day);
    if (matchDay.isBefore(today)) {
      CustomToast.instance.showFailureToast(
        title: 'invalid_date'.tr,
        message: 'cannot_schedule_past'.tr,
      );
      return null;
    }

    try {
      isSearchingMatch.value = true;
      hasError.value = false;

      // ── Conflict check (only for legacy flow with a specific court) ──────
      if (!isGeoFlow && selectedCourt.value != null) {
        final hasConflict = await _matchService.hasConflictingMatch(
          courtId: selectedCourt.value!.id,
          scheduledDate: selectedDate.value,
          scheduledTime: selectedTimeSlot.value,
        );
        if (hasConflict) {
          CustomToast.instance.showFailureToast(
            title: 'time_slot_taken'.tr,
            message: 'time_slot_conflict'.tr,
          );
          return null;
        }
      }

      // ── 2v2 Partner Email Validation ──────────────────────────────────────
      String? invitedPartnerId;
      if (selectedMatchType.value == MatchType.twoVsTwo && hasPartner.value && partnerEmail.value.isNotEmpty) {
        try {
           final response = await Supabase.instance.client.from('users').select('id').eq('email', partnerEmail.value.trim().toLowerCase()).maybeSingle();
           if (response != null) {
              invitedPartnerId = response['id'];
              if (invitedPartnerId == playerId) {
                 CustomToast.instance.showFailureToast(title: 'error'.tr, message: 'No puedes invitarte a ti mismo.');
                 return null;
              }
           } else {
              CustomToast.instance.showFailureToast(title: 'error'.tr, message: 'No se encontró un usuario con ese correo.');
              return null;
           }
        } catch (e) {
           CustomToast.instance.showFailureToast(title: 'error'.tr, message: 'Error verificando el correo.');
           return null;
        }
      }

      // ── Try joining an existing match ─────────────────────────────────────
      if (selectedMatchMode.value == MatchMode.competitive && invitedPartnerId == null) {
        // Resolve sportId early so we can filter the search by sport
        final sportIdForSearch = sportUUIDMap.isNotEmpty
            ? sportUUIDMap[selectedSport.value]
            : null;
        MatchModel? existingMatch;

        if (isGeoFlow) {
          existingMatch = await _matchService.findAvailableMatchByClubs(
            clubIds: preferredClubIds.toList(),
            scheduledDate: selectedDate.value,
            scheduledTime: selectedTimeSlot.value,
            scheduledEndTime: selectedEndTimeSlot.value,
            matchType: selectedMatchType.value,
            currentPlayerId: playerId,
            sportId: sportIdForSearch,
          );
        } else {
          existingMatch = await _matchService.findAvailableMatch(
            courtId: selectedCourt.value!.id,
            scheduledDate: selectedDate.value,
            scheduledTime: selectedTimeSlot.value,
            scheduledEndTime: selectedEndTimeSlot.value,
            matchType: selectedMatchType.value,
            currentPlayerId: playerId,
            sportId: sportIdForSearch,
          );
        }

        if (existingMatch != null) {
          final joinedMatch = await _matchService.joinMatch(existingMatch.id, playerId);
          if (joinedMatch != null) {
            currentMatch.value = joinedMatch;
            _subscribeToMatch(joinedMatch.id);
            await loadPlayerMatches();
            CustomToast.instance.showSuccessToast(
              title: 'match_found'.tr,
              message: '${'matched_with'.tr} ${joinedMatch.player1Name}',
            );
            return joinedMatch;
          }
        }
      }

      // ── Ticket validation ─────────────────────────────────────────────────
      bool needsTicket = Get.isRegistered<TicketController>();
      final String requiredTicketType = selectedMatchType.value == MatchType.oneVsOne ? 'singles' : 'doubles';
      if (needsTicket) {
        final ticketController = TicketController.instance;
        if (!ticketController.hasTickets(requiredTicketType)) {
          CustomToast.instance.showWarningToast(
            title: 'No tienes tickets',
            message: 'Necesitas un ticket de ${requiredTicketType == "singles" ? "Singles (1v1)" : "Dobles (2v2)"} para jugar.',
          );
          return null;
        }
      }

      // ── Resolve sport UUID ────────────────────────────────────────────────
      // sportUUIDMap is populated by loadSportsFromDb() which runs async on init.
      // If the user navigates to match creation before it finishes, wait for it.
      if (sportUUIDMap.isEmpty) {
        await loadSportsFromDb();
      }

      // Helper: strip common diacritics so 'Pádel' == 'Padel' == 'PADEL'
      String _normalize(String s) => s
          .toLowerCase()
          .replaceAll(RegExp(r'[áàäâã]'), 'a')
          .replaceAll(RegExp(r'[éèëê]'), 'e')
          .replaceAll(RegExp(r'[íìïî]'), 'i')
          .replaceAll(RegExp(r'[óòöôõ]'), 'o')
          .replaceAll(RegExp(r'[úùüû]'), 'u')
          .replaceAll(RegExp(r'[ñ]'), 'n');

      String? actualSportId = sportUUIDMap[selectedSport.value];

      // Fallback 1: case-insensitive + accent-insensitive match in the cached map.
      if (actualSportId == null && selectedSport.value.isNotEmpty) {
        final normalizedSelected = _normalize(selectedSport.value);
        final entry = sportUUIDMap.entries.toList().firstWhereOrNull(
          (e) => _normalize(e.key) == normalizedSelected,
        );
        actualSportId = entry?.value;
      }

      // Fallback 2: if still null, query the DB directly (handles edge cases
      // where the map was populated before the sport was seeded).
      if (actualSportId == null && selectedSport.value.isNotEmpty) {
        try {
          final normalizedSelected = _normalize(selectedSport.value);
          final rows = await Supabase.instance.client
              .from('sports')
              .select('id, name');
          for (final row in rows) {
            final dbName = row['name'] as String? ?? '';
            if (_normalize(dbName) == normalizedSelected) {
              actualSportId = row['id'] as String?;
              // Update map so next call is instant
              if (actualSportId != null) sportUUIDMap[dbName] = actualSportId!;
              break;
            }
          }
        } catch (e) {
          print('⚠️ Sport DB fallback error: $e');
        }
      }

      // Court sports override: prefer the UUID from the actual court's sport
      // list because it's the ground truth for that venue.
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

      if (actualSportId == null) {
        CustomToast.instance.showWarningToast(
          title: 'Deporte no disponible',
          message: 'No se pudo determinar el deporte seleccionado. Intenta de nuevo.',
        );
        return null;
      }

      // ── MANTENER EL RANGO DE BÚSQUEDA ──────────────────────────────────
      // El usuario solicitó mantener la búsqueda dinámica en el rango, y
      // fijar la hora solo cuando se complete la sala (estado matched).
      
      final newMatch = MatchModel(
        id: '',
        courtId: isGeoFlow ? null : selectedCourt.value?.id,  // null in geo-flow
        preferredClubIds: isGeoFlow ? preferredClubIds.toList() : [],
        sportId: actualSportId,
        matchCategory: selectedCategory.value,
        player1Id: playerId,
        invitedPlayer2Id: invitedPartnerId,
        matchType: selectedMatchType.value,
        matchMode: selectedMatchMode.value,
        status: MatchStatus.waitingForOpponent,
        scheduledDate: selectedDate.value,
        scheduledTime: selectedTimeSlot.value,
        scheduledEndTime: selectedEndTimeSlot.value.isNotEmpty
            ? selectedEndTimeSlot.value
            : null,
      );

      // ── Navigate to ReviewSummary & confirm ───────────────────────────────
      // ── Create the match directly ─────────────────────────────────────────
      print('🔥 MatchController: Iniciando creación en DB...');
      final createdMatch = await _matchService.createMatch(newMatch);
      
      if (createdMatch != null) {
        print('🔥 MatchController: Match creado (ID: ${createdMatch.id}). Deduciendo ticket...');
        
        if (needsTicket) {
          final success = await TicketController.instance.useTicketForMatch(
            createdMatch.id, 
            requiredTicketType
          );
          
          if (!success) {
            print('🔥 MatchController: Error deduciendo ticket. Cancelando match...');
            await _matchService.cancelMatch(createdMatch.id);
            return null;
          }
        }
        
        currentMatch.value = createdMatch;
        inviteCode.value = createdMatch.inviteCode ?? '';
        _subscribeToMatch(createdMatch.id);
        await loadPlayerMatches();
        
        print('🔥 MatchController: Flujo completado con éxito.');
        return createdMatch;
      }
      
      print('🔥 MatchController: _matchService.createMatch retornó null');
      return null;

    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to create match: $e';
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'failed_create_match'.tr,
      );
      return null;
    } finally {
      isSearchingMatch.value = false;
    }
  }

  /// Join match by invite code
  Future<MatchModel?> joinMatchByCode(String code) async {
    final playerId = currentUserId;
    if (playerId == null) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'please_login_continue'.tr,
      );
      return null;
    }

    try {
      isJoiningMatch.value = true;
      hasError.value = false;

      // TODO(payment): Ticket/payment enforcement is temporarily disabled.
      // if (Get.isRegistered<TicketController>()) {
      //   final ticketController = TicketController.instance;
      //   if (!ticketController.hasTickets) {
      //     CustomToast.instance.showWarningToast(
      //       title: 'no_tickets'.tr,
      //       message: 'need_ticket_to_play'.tr,
      //     );
      //     return null;
      //   }
      // }

      final match = await _matchService.joinMatchByCode(code, playerId);
      if (match != null) {
        // TODO(payment): Temporarily skipping ticket deduction.
        // if (Get.isRegistered<TicketController>()) {
        //   await TicketController.instance.useTicketForMatch(match.id);
        // }
        currentMatch.value = match;
        _subscribeToMatch(match.id);

        // Refresh player's match lists so status is accurate
        await loadPlayerMatches();

        CustomToast.instance.showSuccessToast(
          title: 'joined_match'.tr,
          message: '${'now_matched_with'.tr} ${match.player1Name}',
        );
        return match;
      } else {
        CustomToast.instance.showFailureToast(
          title: 'invalid_code'.tr,
          message: 'match_not_found_or_full'.tr,
        );
        return null;
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to join match: $e';
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'failed_join_match'.tr,
      );
      return null;
    } finally {
      isJoiningMatch.value = false;
    }
  }

  /// Cancel a match
  Future<bool> cancelMatch(String matchId) async {
    // Find match for optimistic UI (to know which ticket type to refund)
    final match = playerMatches.firstWhereOrNull((m) => m.id == matchId);
    final ticketController = Get.find<TicketController>();
    bool wasOptimistic = false;

    try {
      isLoading.value = true;

      // Optimistic Update: Increment ticket balance immediately
      if (match != null) {
        if (match.matchType == MatchType.oneVsOne) {
          ticketController.singlesBalance.value++;
        } else {
          ticketController.doublesBalance.value++;
        }
        wasOptimistic = true;
      }

      final response = await Supabase.instance.client.rpc(
        'cancel_match_and_refund',
        params: {
          'p_match_id': matchId,
          'p_user_id': currentUserId,
        },
      );

      // Successfully cancelled
      currentMatch.value = null;
      await loadPlayerMatches();

      Get.snackbar(
        'Partido Cancelado',
        'Tu partido ha sido cancelado y tu ticket ha sido devuelto a tu cuenta.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      return true;
    } catch (e) {
      print('🔥 ERROR CANCELAR: $e');

      // Revert Optimistic Update if it was applied
      if (wasOptimistic && match != null) {
        if (match.matchType == MatchType.oneVsOne) {
          ticketController.singlesBalance.value--;
        } else {
          ticketController.doublesBalance.value--;
        }
      }

      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'failed_cancel_match'.tr,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Copy invite code to clipboard
  void copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    CustomToast.instance.showSuccessToast(
      title: 'copied'.tr,
      message: 'invite_code_copied'.tr,
    );
  }

  // ==================== PLAYER MATCH OPERATIONS ====================

  // Duplicates removed

  /// Join an available match
  Future<MatchModel?> joinAvailableMatch(String matchId) async {
    final playerId = currentUserId;
    if (playerId == null) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'please_login_continue'.tr,
      );
      return null;
    }

    try {
      isJoiningMatch.value = true;
      joiningMatchId.value = matchId;
      hasError.value = false;

      // TODO(payment): Ticket/payment enforcement is temporarily disabled.
      // if (Get.isRegistered<TicketController>()) {
      //   final ticketController = TicketController.instance;
      //   if (!ticketController.hasTickets) {
      //     CustomToast.instance.showWarningToast(
      //       title: 'no_tickets'.tr,
      //       message: 'need_ticket_to_play'.tr,
      //     );
      //     return null;
      //   }
      // }

      final match = await _matchService.joinMatch(matchId, playerId);
      if (match != null) {
        // TODO(payment): Temporarily skipping ticket deduction.
        // if (Get.isRegistered<TicketController>()) {
        //   await TicketController.instance.useTicketForMatch(match.id);
        // }
        currentMatch.value = match;
        _subscribeToMatch(match.id);

        // Refresh available matches list
        await loadAvailableMatchesToJoin();
        await loadPlayerMatches();

        CustomToast.instance.showSuccessToast(
          title: 'joined_match'.tr,
          message:
              '${'now_matched_with'.tr} ${match.player1Name ?? 'your opponent'}',
        );
        return match;
      } else {
        CustomToast.instance.showFailureToast(
          title: 'error'.tr,
          message: 'failed_join_match_full'.tr,
        );
        return null;
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Failed to join match: $e';
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'failed_join_match'.tr,
      );
      return null;
    } finally {
      isJoiningMatch.value = false;
      joiningMatchId.value = null;
    }
  }

  /// Accept an invitation (2v2 partner)
  Future<void> acceptInvitation(MatchModel match) async {
    final playerId = currentUserId;
    if (playerId == null) return;

    bool needsTicket = Get.isRegistered<TicketController>();
    final String requiredTicketType = match.matchType == MatchType.oneVsOne ? 'singles' : 'doubles';

    if (needsTicket) {
      final ticketController = TicketController.instance;
      if (!ticketController.hasTickets(requiredTicketType)) {
        CustomToast.instance.showWarningToast(
          title: 'No tienes tickets',
          message: 'Necesitas un ticket de ${requiredTicketType == "singles" ? "Singles (1v1)" : "Dobles (2v2)"} para jugar.',
        );
        return;
      }
    }

    Get.to(() => ReviewSummary(
      onConfirm: () async {
        // 1. Unirse al match (llena player2_id)
        final joinedMatch = await _matchService.joinMatch(match.id, playerId);
        if (joinedMatch != null) {
          // 2. Consume ticket
          if (needsTicket) {
             final success = await TicketController.instance.useTicketForMatch(match.id, requiredTicketType);
             if (!success) {
                CustomToast.instance.showFailureToast(title: 'Error', message: 'Error procesando el ticket.');
                return false;
             }
          }
          
          currentMatch.value = joinedMatch;
          _subscribeToMatch(match.id);
          await loadPlayerMatches();
          return true;
        }
        return false;
      }
    ));
  }

  /// Reject an invitation (2v2 partner)
  Future<void> rejectInvitation(MatchModel match) async {
    try {
      isLoading.value = true;
      // 1. Cancel match entirely
      final success = await _matchService.cancelMatch(match.id);
      if (success) {
        // 2. Refund ticket to the host
        if (Get.isRegistered<TicketController>()) {
           final refundType = match.matchType == MatchType.oneVsOne ? 'singles' : 'doubles';
           await TicketController.instance.refundTicketForUser(match.id, match.player1Id, refundType);
        }
        
        // Remove locally from UI if present
        availableMatchesToJoin.removeWhere((m) => m.id == match.id);
        
        CustomToast.instance.showSuccessToast(
          title: 'invitation_rejected'.tr,
          message: 'match_cancelled'.tr,
        );
      }
    } catch (e) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'Acción fallida.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Get match by ID
  Future<void> loadMatch(String matchId) async {
    try {
      isLoading.value = true;
      final match = await _matchService.getMatchById(matchId);
      currentMatch.value = match;
      if (match != null) {
        _subscribeToMatch(match.id);
      }
    } catch (e) {
      print('Error loading match: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Confirm check-in for the current player
  Future<bool> confirmCheckIn(String matchId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
      isLoading.value = true;

      // Get the latest match data to identify the player's role
      final match = await _matchService.getMatchById(matchId);
      if (match == null) {
        CustomToast.instance.showFailureToast(
          title: 'error'.tr,
          message: 'match_not_found'.tr,
        );
        return false;
      }

      int? playerIndex;
      if (match.player1Id == userId) {
        playerIndex = 1;
      } else if (match.player2Id == userId) {
        playerIndex = 2;
      } else if (match.player3Id == userId) {
        playerIndex = 3;
      } else if (match.player4Id == userId) {
        playerIndex = 4;
      } else {
        CustomToast.instance.showFailureToast(
          title: 'Acceso Denegado',
          message:
              'No eres participante de este partido.',
        );
        return false;
      }

      final updatedMatch = await _matchService.updateCheckInStatus(
        matchId,
        player1CheckedIn: playerIndex == 1 ? true : null,
        player2CheckedIn: playerIndex == 2 ? true : null,
        player3CheckedIn: playerIndex == 3 ? true : null,
        player4CheckedIn: playerIndex == 4 ? true : null,
      );

      if (updatedMatch != null) {
        // Refresh local data
        await loadPlayerMatches();
        CustomToast.instance.showSuccessToast(
          title: 'Check-in Exitoso',
          message: 'Tu asistencia ha sido confirmada.',
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error confirming check-in: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== REFEREE OPERATIONS ====================

  /// Load referee's available matches (marketplace - orphan matches)
  Future<void> loadRefereeAvailableMatches() async {
    print('📋 LOADING REFEREE MARKETPLACE (AVAILABLE MATCHES)');
    try {
      isLoading.value = true;
      print('   📡 Fetching orphan confirmed matches from database...');
      final matches = await _matchService.getRefereeAvailableMatches();
      print('   ✅ Received ${matches.length} orphan matches');

      // Sort by proximity if permission is granted
      final sortedMatches = await _sortMatchesByProximity(matches);

      // Filter out declined matches
      final filtered =
          sortedMatches.where((m) => !declinedMatchIds.contains(m.id)).toList();
      refereeAvailableMatches.assignAll(filtered);
      print('   ✅ Marketplace loaded and sorted');
    } catch (e) {
      print('   ❌ Error loading referee available matches: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Sort matches by proximity to the current referee
  Future<List<MatchModel>> _sortMatchesByProximity(
      List<MatchModel> matches) async {
    try {
      print('   📍 Requesting location for sorting...');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        print('   ⚠️ Location permission denied, skipping sorting');
        return matches;
      }

      final Position position = await Geolocator.getCurrentPosition();
      print(
          '   ✅ Location obtained: ${position.latitude}, ${position.longitude}');

      final List<MatchModel> sorted = List.from(matches);
      sorted.sort((a, b) {
        if (a.court == null && b.court == null) return 0;
        if (a.court == null) return -1; // Place Geo-Match at the top so it's not hidden
        if (b.court == null) return 1;

        final double distA = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          a.court!.latitude,
          a.court!.longitude,
        );
        final double distB = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          b.court!.latitude,
          b.court!.longitude,
        );
        return distA.compareTo(distB);
      });

      return sorted;
    } catch (e) {
      print('   ❌ Error sorting by proximity: $e');
      return matches;
    }
  }

  /// Load referee's scheduled matches (matches claimed by the user)
  Future<void> loadRefereeScheduledMatches() async {
    print('📅 LOADING REFEREE SCHEDULED MATCHES (MY SCHEDULE)');
    final refereeId = currentUserId;
    if (refereeId == null) return;

    try {
      isLoading.value = true;
      final matches = await _matchService.getRefereeScheduledMatches(refereeId);
      print('   ✅ Received ${matches.length} claimed matches');
      refereeScheduledMatches.assignAll(matches);
    } catch (e) {
      print('   ❌ Error loading referee scheduled matches: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load all referee matches
  Future<void> loadRefereeAllMatches() async {
    final refereeId = currentUserId;
    if (refereeId == null) return;

    try {
      isLoading.value = true;
      final matches = await _matchService.getRefereeMatches(refereeId);
      refereeAllMatches.assignAll(matches);
    } catch (e) {
      print('Error loading referee matches: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load completed/cancelled matches for referee history
  Future<void> loadRefereeCompletedMatches() async {
    final refereeId = currentUserId;
    if (refereeId == null) return;

    try {
      isLoading.value = true;
      final matches = await _matchService.getRefereeCompletedMatches(refereeId);
      refereeCompletedMatches.assignAll(matches);
    } catch (e) {
      print('Error loading referee completed matches: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Claim a match (referee takes an orphan match)
  Future<bool> claimMatch(String matchId) async {
    final refereeId = currentUserId;
    if (refereeId == null) return false;

    try {
      isLoading.value = true;
      acceptingMatchId.value = matchId;

      print('   🚀 Claiming match: $matchId');
      final match = await _matchService.claimMatch(matchId, refereeId);

      if (match != null) {
        print('   ✅ Match claimed successfully');
        await loadRefereeAvailableMatches();
        await loadRefereeScheduledMatches();

        CustomToast.instance.showSuccessToast(
          title: 'match_claimed'.tr,
          message: 'you_will_referee'.tr,
        );
        return true;
      } else {
        print('   ❌ Claim failed (likely already taken or race condition)');
        CustomToast.instance.showFailureToast(
          title: 'error'.tr,
          message: 'failed_claim_match_taken'.tr,
        );
        // Refresh to remove orphan match that was taken
        await loadRefereeAvailableMatches();
        return false;
      }
    } catch (e) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'failed_accept_match'.tr,
      );
      return false;
    } finally {
      isLoading.value = false;
      acceptingMatchId.value = null;
    }
  }

  /// Decline a match (referee removes it from their available list)
  Future<bool> declineMatch(String matchId) async {
    try {
      // Add to declined set so it's filtered out
      declinedMatchIds.add(matchId);
      // Remove from the available matches list immediately
      refereeAvailableMatches.removeWhere((m) => m.id == matchId);

      CustomToast.instance.showSuccessToast(
        title: 'match_declined'.tr,
        message: 'match_removed_from_list'.tr,
      );
      return true;
    } catch (e) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'failed_decline_match'.tr,
      );
      return false;
    }
  }

  /// Bypass check-in (temporary for testing)
  Future<void> bypassCheckIn(String matchId) async {
    try {
      isLoading.value = true;
      final matchToBypass = refereeScheduledMatches.firstWhereOrNull((m) => m.id == matchId);
      
      final match = await _matchService.updateCheckInStatus(
        matchId,
        player1CheckedIn: true,
        player2CheckedIn: true,
        player3CheckedIn: matchToBypass?.matchType == MatchType.twoVsTwo ? true : null,
        player4CheckedIn: matchToBypass?.matchType == MatchType.twoVsTwo ? true : null,
      );
      
      if (match != null) {
        // Update local state if needed
        final index = refereeScheduledMatches.indexWhere((m) => m.id == matchId);
        if (index != -1) {
          refereeScheduledMatches[index] = match;
        }
        if (currentMatch.value?.id == matchId) {
          currentMatch.value = match;
        }

        CustomToast.instance.showSuccessToast(
          title: 'Check-in Bypassed',
          message: match.matchType == MatchType.twoVsTwo 
            ? 'Los 4 jugadores marcados como presentes.'
            : 'Ambos jugadores marcados como presentes.',
        );
      }
    } catch (e) {
      print('Error in bypassCheckIn: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Start a match (referee starts the match) - only on match day
  Future<bool> startMatch(String matchId) async {
    try {
      isLoading.value = true;

      final matchToStart =
          refereeScheduledMatches.firstWhereOrNull((m) => m.id == matchId);
      if (matchToStart != null && matchToStart.isPastMatch) {
        CustomToast.instance.showFailureToast(
          title: 'cannot_start_match'.tr,
          message: 'match_past_cannot_start'.tr,
        );
        return false;
      }
      if (matchToStart != null && matchToStart.isScheduledForFuture) {
        CustomToast.instance.showFailureToast(
          title: 'cannot_start_match'.tr,
          message: 'match_scheduled_for'
              .trParams({'date': matchToStart.formattedDate}),
        );
        return false;
      }

      final match = await _matchService.startMatch(matchId);
      if (match != null) {
        currentMatch.value = match;
        await loadRefereeScheduledMatches();

        CustomToast.instance.showSuccessToast(
          title: 'match_started'.tr,
          message: 'match_now_in_progress'.tr,
        );
        return true;
      }
      return false;
    } catch (e) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'failed_start_match'.tr,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Complete a match with winner or draw - cannot complete past scheduled matches
  Future<bool> completeMatch(String matchId,
      {String? winnerId, Map<String, dynamic>? scoreData}) async {
    try {
      isLoading.value = true;

      // Only allow completing matches that are currently in progress
      final matchToComplete =
          refereeScheduledMatches.firstWhereOrNull((m) => m.id == matchId);
      if (matchToComplete != null &&
          matchToComplete.status != MatchStatus.inProgress) {
        CustomToast.instance.showFailureToast(
          title: 'cannot_complete'.tr,
          message: 'only_in_progress_completed'.tr,
        );
        return false;
      }

      final match = await _matchService.completeMatch(matchId,
          winnerId: winnerId, scoreData: scoreData);
      if (match != null) {
        currentMatch.value = match;
        
        // Refresh local data
        await loadRefereeScheduledMatches();
        await loadRefereeCompletedMatches();
        await loadPlayerMatches(); 

        // --- PRODUCT ADJUSTMENTS: REACTIVE REFRESH ---
        // 1. Refresh Referee Payout/Balance (Wallet)
        if (Get.isRegistered<PayoutController>()) {
          Get.find<PayoutController>().refresh();
        }

        // 2. Refresh Player Stats & Rankings (ELO)
        // Note: fetchRealUserRankings and refreshUserData will query Supabase for latest ELO/Stats
        if (Get.isRegistered<ProfileController>()) {
          final profileController = Get.find<ProfileController>();
          await profileController.fetchRealUserRankings();
          await profileController.refreshUserData();
        }

        CustomToast.instance.showSuccessToast(
          title: 'match_completed'.tr,
          message: 'match_recorded'.tr,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('❌ [MatchController] Error completing match: $e');
      Get.snackbar(
        'Error de Servidor',
        'No se pudo finalizar el partido. Verifica los puntajes y la conexión. Error: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 10),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Initialize referee subscriptions
  void initRefereeSubscriptions() {
    final refereeId = currentUserId;
    if (refereeId == null) return;

    _refereeSubscription = _matchService.subscribeToRefereeMatches(
      refereeId,
      onNewMatch: (match) {
        // Refresh matches when a genuinely new match comes in
        loadRefereeAvailableMatches();
        loadRefereeScheduledMatches();

        // Show notification only for new matches
        CustomToast.instance.showSuccessToast(
          title: 'new_match'.tr,
          message: 'new_match_scheduled_at'
              .trParams({'court': match.court?.name ?? 'your court'}),
        );
      },
      onMatchUpdated: () {
        // Silently refresh data on updates (score changes, status changes)
        loadRefereeAvailableMatches();
        loadRefereeScheduledMatches();
      },
    );
  }

  // ==================== PRIVATE METHODS ====================

  /// Subscribe to match updates
  void _subscribeToMatch(String matchId) {
    _matchSubscription?.unsubscribe();
    _matchSubscription = _matchService.subscribeToMatch(matchId, (match) {
      currentMatch.value = match;

      // Update the match in playerMatches list for accurate status display
      final index = playerMatches.indexWhere((m) => m.id == match.id);
      if (index != -1) {
        playerMatches[index] = match;
        activeMatches
            .assignAll(playerMatches.where((m) => m.status.isActive).toList());
      }

      // Show notifications based on status change
      if (match.status == MatchStatus.matched) {
        CustomToast.instance.showSuccessToast(
          title: 'opponent_found'.tr,
          message: 'your_match_complete'.tr,
        );
      } else if (match.status == MatchStatus.confirmed) {
        CustomToast.instance.showSuccessToast(
          title: 'match_confirmed'.tr,
          message: 'referee_accepted_match'.tr,
        );
      } else if (match.status == MatchStatus.inProgress) {
        CustomToast.instance.showSuccessToast(
          title: 'match_started_title'.tr,
          message: 'match_now_in_progress_title'.tr,
        );
      }
    });
  }

  /// Initialize subscription to available matches
  void _initializeAvailableMatchesSubscription() {
    final playerId = currentUserId;
    if (playerId == null) return;

    print(
        '🔔 Initializing available matches subscription for player: $playerId');
    _availableMatchesSubscription?.unsubscribe();
    _availableMatchesSubscription = _matchService.subscribeToAvailableMatches(
      playerId,
      () async {
        // Reload available matches and player's own matches when changes detected
        await loadAvailableMatchesToJoin();
        await loadPlayerMatches();
      },
    );
  }

  /// Get available time slots for a date
  List<String> getAvailableTimeSlots() {
    // Default time slots - in production, these would come from court availability
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
