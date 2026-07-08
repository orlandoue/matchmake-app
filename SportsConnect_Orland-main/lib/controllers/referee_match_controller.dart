import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:orland_sports/controllers/current_user_mixin.dart';
import 'package:orland_sports/controllers/payout_controller.dart';
import 'package:orland_sports/controllers/player_matches_controller.dart';
import 'package:orland_sports/controllers/profile_controller.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/match_model.dart';
import 'package:orland_sports/services/match_service.dart';
import 'package:orland_sports/services/match_realtime_service.dart';
import 'package:orland_sports/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Everything a referee does with matches.
///
/// Single responsibility: the referee's marketplace (available matches),
/// their schedule, history, and the lifecycle actions they perform (claim,
/// decline, check-in bypass, start, complete). Only registered in
/// RefereeBinding.
class RefereeMatchController extends GetxController with CurrentUserMixin {
  static RefereeMatchController get instance =>
      Get.find<RefereeMatchController>();

  final _matchService = MatchService.instance;
  final _realtime = MatchRealtimeService.instance;

  final RxBool isLoading = false.obs;

  // Per-match loading IDs (to show loader only on the specific card)
  final RxnString acceptingMatchId = RxnString(null);

  // Referee matches
  final RxList<MatchModel> refereeAvailableMatches = <MatchModel>[].obs;
  final RxList<MatchModel> refereeScheduledMatches = <MatchModel>[].obs;
  final RxList<MatchModel> refereeAllMatches = <MatchModel>[].obs;
  final RxList<MatchModel> refereeCompletedMatches = <MatchModel>[].obs;

  // Declined match IDs (referee chose to skip these)
  final RxSet<String> declinedMatchIds = <String>{}.obs;

  // The match the referee is currently acting on
  final Rx<MatchModel?> currentMatch = Rx<MatchModel?>(null);

  RealtimeChannel? _refereeSubscription;

  @override
  void onClose() {
    _refereeSubscription?.unsubscribe();
    super.onClose();
  }

  /// Load referee's available matches (marketplace - orphan matches)
  Future<void> loadRefereeAvailableMatches() async {
    print('📋 LOADING REFEREE MARKETPLACE (AVAILABLE MATCHES)');
    try {
      isLoading.value = true;
      print('   📡 Fetching orphan confirmed matches from database...');
      final matches = await _matchService.getRefereeAvailableMatches();
      print('   ✅ Received ${matches.length} orphan matches');

      final sortedMatches = await _sortMatchesByProximity(matches);

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
      print('   ✅ Location obtained: ${position.latitude}, ${position.longitude}');

      final List<MatchModel> sorted = List.from(matches);
      sorted.sort((a, b) {
        if (a.court == null && b.court == null) return 0;
        if (a.court == null) return -1; // Place Geo-Match at the top
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
      declinedMatchIds.add(matchId);
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
      final matchToBypass =
          refereeScheduledMatches.firstWhereOrNull((m) => m.id == matchId);

      final match = await _matchService.updateCheckInStatus(
        matchId,
        player1CheckedIn: true,
        player2CheckedIn: true,
        player3CheckedIn:
            matchToBypass?.matchType == MatchType.twoVsTwo ? true : null,
        player4CheckedIn:
            matchToBypass?.matchType == MatchType.twoVsTwo ? true : null,
      );

      if (match != null) {
        final index =
            refereeScheduledMatches.indexWhere((m) => m.id == matchId);
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

        await loadRefereeScheduledMatches();
        await loadRefereeCompletedMatches();
        if (Get.isRegistered<PlayerMatchesController>()) {
          await PlayerMatchesController.instance.loadPlayerMatches();
        }

        // --- PRODUCT ADJUSTMENTS: REACTIVE REFRESH ---
        if (Get.isRegistered<PayoutController>()) {
          Get.find<PayoutController>().refresh();
        }

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
      print('❌ [RefereeMatchController] Error completing match: $e');
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

    _refereeSubscription = _realtime.subscribeToRefereeMatches(
      refereeId,
      onNewMatch: (match) {
        loadRefereeAvailableMatches();
        loadRefereeScheduledMatches();

        CustomToast.instance.showSuccessToast(
          title: 'new_match'.tr,
          message: 'new_match_scheduled_at'
              .trParams({'court': match.court?.name ?? 'your court'}),
        );
      },
      onMatchUpdated: () {
        loadRefereeAvailableMatches();
        loadRefereeScheduledMatches();
      },
    );
  }
}
