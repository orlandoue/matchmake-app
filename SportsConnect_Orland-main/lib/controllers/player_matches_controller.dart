import 'package:get/get.dart';
import 'package:orland_sports/controllers/current_user_mixin.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/match_model.dart';
import 'package:orland_sports/services/match_service.dart';
import 'package:orland_sports/services/match_realtime_service.dart';
import 'package:orland_sports/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The player's view of matches, kept live via realtime.
///
/// Single responsibility: load and expose the current player's matches
/// (active, joinable, invitations, history) and the currently-focused match,
/// and keep them synced through the match/available-matches channels.
class PlayerMatchesController extends GetxController with CurrentUserMixin {
  static PlayerMatchesController get instance =>
      Get.find<PlayerMatchesController>();

  final _matchService = MatchService.instance;
  final _realtime = MatchRealtimeService.instance;

  final RxBool isLoading = false.obs;

  // Match data
  final RxList<MatchModel> playerMatches = <MatchModel>[].obs;
  final RxList<MatchModel> activeMatches = <MatchModel>[].obs;
  final RxList<MatchModel> availableMatchesToJoin = <MatchModel>[].obs;
  final RxList<MatchModel> pendingInvitations = <MatchModel>[].obs;
  final Rx<MatchModel?> currentMatch = Rx<MatchModel?>(null);

  RealtimeChannel? _matchSubscription;
  RealtimeChannel? _availableMatchesSubscription;

  // ==================== HISTORY COMPUTED GETTERS ====================

  List<MatchModel> get completedMatches =>
      playerMatches.where((m) => m.status == MatchStatus.completed).toList();

  List<MatchModel> get wonMatches =>
      completedMatches.where((m) => m.winnerId == currentUserId).toList();

  List<MatchModel> get lostMatches => completedMatches
      .where((m) => m.winnerId != null && m.winnerId != currentUserId)
      .toList();

  List<MatchModel> get historyMatches => playerMatches
      .where((m) =>
          m.status == MatchStatus.completed ||
          m.status == MatchStatus.cancelled)
      .toList();

  @override
  void onInit() {
    super.onInit();
    _initializeAvailableMatchesSubscription();
  }

  @override
  void onClose() {
    _matchSubscription?.unsubscribe();
    _availableMatchesSubscription?.unsubscribe();
    super.onClose();
  }

  /// Load player's active matches (pending, confirmed, etc.)
  Future<void> loadPlayerMatches() async {
    final playerId = currentUserId;
    if (playerId == null) return;

    try {
      isLoading.value = true;
      final matches = await _matchService.getPlayerMatches(playerId);
      playerMatches.assignAll(matches);

      activeMatches.assignAll(matches
          .where((m) =>
              m.status != MatchStatus.completed &&
              m.status != MatchStatus.cancelled)
          .toList());

      if (activeMatches.isNotEmpty) {
        currentMatch.value = activeMatches.first;
        subscribeToCurrentMatch(currentMatch.value!.id);
      } else if (currentMatch.value != null &&
          (currentMatch.value!.status == MatchStatus.completed ||
              currentMatch.value!.status == MatchStatus.cancelled)) {
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
      final matches =
          await _matchService.getAvailableMatchesForPlayer(playerId);
      availableMatchesToJoin.assignAll(matches);

      final invitations = await _matchService.getPendingInvitations(playerId);
      pendingInvitations.assignAll(invitations);
    } catch (e) {
      print('Error loading available matches: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load a single match by ID and focus it.
  Future<void> loadMatch(String matchId) async {
    try {
      isLoading.value = true;
      final match = await _matchService.getMatchById(matchId);
      currentMatch.value = match;
      if (match != null) {
        subscribeToCurrentMatch(match.id);
      }
    } catch (e) {
      print('Error loading match: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== REALTIME ====================

  /// Subscribe to the given match's live updates and reflect them locally.
  void subscribeToCurrentMatch(String matchId) {
    _matchSubscription?.unsubscribe();
    _matchSubscription = _realtime.subscribeToMatch(matchId, (match) {
      currentMatch.value = match;

      final index = playerMatches.indexWhere((m) => m.id == match.id);
      if (index != -1) {
        playerMatches[index] = match;
        activeMatches
            .assignAll(playerMatches.where((m) => m.status.isActive).toList());
      }

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

  void _initializeAvailableMatchesSubscription() {
    final playerId = currentUserId;
    if (playerId == null) return;

    print('🔔 Initializing available matches subscription for player: $playerId');
    _availableMatchesSubscription?.unsubscribe();
    _availableMatchesSubscription = _realtime.subscribeToAvailableMatches(
      playerId,
      () async {
        await loadAvailableMatchesToJoin();
        await loadPlayerMatches();
      },
    );
  }
}
