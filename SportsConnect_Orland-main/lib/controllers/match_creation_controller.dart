import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:orland_sports/controllers/current_user_mixin.dart';
import 'package:orland_sports/controllers/match_form_controller.dart';
import 'package:orland_sports/controllers/player_matches_controller.dart';
import 'package:orland_sports/controllers/ticket_controller.dart';
import 'package:orland_sports/View/Screens/Users/matchmaking/ReviewSummary.dart';
import 'package:orland_sports/enums/match_status.dart';
import 'package:orland_sports/models/match_model.dart';
import 'package:orland_sports/services/match_service.dart';
import 'package:orland_sports/services/matchmaking_service.dart';
import 'package:orland_sports/utils/custom_toast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Player-initiated writes on matches: create, join, accept/reject, cancel.
///
/// Single responsibility: orchestrate the mutations a player triggers, reading
/// configuration from [MatchFormController], enforcing tickets via
/// [TicketController], and refreshing [PlayerMatchesController] afterwards.
class MatchCreationController extends GetxController with CurrentUserMixin {
  static MatchCreationController get instance =>
      Get.find<MatchCreationController>();

  final _matchService = MatchService.instance;
  final _matchmaking = MatchmakingService.instance;

  MatchFormController get _form => MatchFormController.instance;
  PlayerMatchesController get _player => PlayerMatchesController.instance;

  final RxBool isSearchingMatch = false.obs;
  final RxBool isJoiningMatch = false.obs;
  final RxnString joiningMatchId = RxnString(null);
  final RxString inviteCode = ''.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  /// Create or join a match.
  /// Supports two flows:
  ///  - GEO flow: preferredClubIds set, courtId = null (admin assigns later)
  ///  - Legacy flow: selectedCourt set explicitly
  Future<MatchModel?> createOrJoinMatch() async {
    final bool isGeoFlow = _form.preferredClubIds.isNotEmpty;

    if (!isGeoFlow && _form.selectedCourt.value == null) {
      CustomToast.instance.showFailureToast(
        title: 'error'.tr,
        message: 'please_select_court'.tr,
      );
      return null;
    }

    if (_form.selectedTimeSlot.value.isEmpty) {
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
    final matchDay = DateTime(_form.selectedDate.value.year,
        _form.selectedDate.value.month, _form.selectedDate.value.day);
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
      if (!isGeoFlow && _form.selectedCourt.value != null) {
        final hasConflict = await _matchmaking.hasConflictingMatch(
          courtId: _form.selectedCourt.value!.id,
          scheduledDate: _form.selectedDate.value,
          scheduledTime: _form.selectedTimeSlot.value,
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
      if (_form.selectedMatchType.value == MatchType.twoVsTwo &&
          _form.hasPartner.value &&
          _form.partnerEmail.value.isNotEmpty) {
        try {
          final response = await Supabase.instance.client
              .from('users')
              .select('id')
              .eq('email', _form.partnerEmail.value.trim().toLowerCase())
              .maybeSingle();
          if (response != null) {
            invitedPartnerId = response['id'];
            if (invitedPartnerId == playerId) {
              CustomToast.instance.showFailureToast(
                  title: 'error'.tr,
                  message: 'No puedes invitarte a ti mismo.');
              return null;
            }
          } else {
            CustomToast.instance.showFailureToast(
                title: 'error'.tr,
                message: 'No se encontró un usuario con ese correo.');
            return null;
          }
        } catch (e) {
          CustomToast.instance.showFailureToast(
              title: 'error'.tr, message: 'Error verificando el correo.');
          return null;
        }
      }

      // ── Try joining an existing match ─────────────────────────────────────
      if (_form.selectedMatchMode.value == MatchMode.competitive &&
          invitedPartnerId == null) {
        final sportIdForSearch = _form.sportUUIDMap.isNotEmpty
            ? _form.sportUUIDMap[_form.selectedSport.value]
            : null;
        MatchModel? existingMatch;

        if (isGeoFlow) {
          existingMatch = await _matchmaking.findAvailableMatchByClubs(
            clubIds: _form.preferredClubIds.toList(),
            scheduledDate: _form.selectedDate.value,
            scheduledTime: _form.selectedTimeSlot.value,
            scheduledEndTime: _form.selectedEndTimeSlot.value,
            matchType: _form.selectedMatchType.value,
            currentPlayerId: playerId,
            sportId: sportIdForSearch,
          );
        } else {
          existingMatch = await _matchmaking.findAvailableMatch(
            courtId: _form.selectedCourt.value!.id,
            scheduledDate: _form.selectedDate.value,
            scheduledTime: _form.selectedTimeSlot.value,
            scheduledEndTime: _form.selectedEndTimeSlot.value,
            matchType: _form.selectedMatchType.value,
            currentPlayerId: playerId,
            sportId: sportIdForSearch,
          );
        }

        if (existingMatch != null) {
          final joinedMatch =
              await _matchService.joinMatch(existingMatch.id, playerId);
          if (joinedMatch != null) {
            _player.currentMatch.value = joinedMatch;
            _player.subscribeToCurrentMatch(joinedMatch.id);
            await _player.loadPlayerMatches();
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
      final String requiredTicketType =
          _form.selectedMatchType.value == MatchType.oneVsOne
              ? 'singles'
              : 'doubles';
      if (needsTicket) {
        final ticketController = TicketController.instance;
        if (!ticketController.hasTickets(requiredTicketType)) {
          CustomToast.instance.showWarningToast(
            title: 'No tienes tickets',
            message:
                'Necesitas un ticket de ${requiredTicketType == "singles" ? "Singles (1v1)" : "Dobles (2v2)"} para jugar.',
          );
          return null;
        }
      }

      // ── Resolve sport UUID ────────────────────────────────────────────────
      final String? actualSportId = await _form.resolveSelectedSportId();
      if (actualSportId == null) {
        CustomToast.instance.showWarningToast(
          title: 'Deporte no disponible',
          message:
              'No se pudo determinar el deporte seleccionado. Intenta de nuevo.',
        );
        return null;
      }

      final newMatch = MatchModel(
        id: '',
        courtId: isGeoFlow ? null : _form.selectedCourt.value?.id,
        preferredClubIds: isGeoFlow ? _form.preferredClubIds.toList() : [],
        sportId: actualSportId,
        matchCategory: _form.selectedCategory.value,
        player1Id: playerId,
        invitedPlayer2Id: invitedPartnerId,
        matchType: _form.selectedMatchType.value,
        matchMode: _form.selectedMatchMode.value,
        status: MatchStatus.waitingForOpponent,
        scheduledDate: _form.selectedDate.value,
        scheduledTime: _form.selectedTimeSlot.value,
        scheduledEndTime: _form.selectedEndTimeSlot.value.isNotEmpty
            ? _form.selectedEndTimeSlot.value
            : null,
        player1CourtSide: _form.selectedCourtSide.value.isNotEmpty
            ? _form.selectedCourtSide.value
            : null,
      );

      print('🔥 MatchCreationController: Iniciando creación en DB...');
      final createdMatch = await _matchService.createMatch(newMatch);

      if (createdMatch != null) {
        print(
            '🔥 MatchCreationController: Match creado (ID: ${createdMatch.id}). Deduciendo ticket...');

        if (needsTicket) {
          final success = await TicketController.instance
              .useTicketForMatch(createdMatch.id, requiredTicketType);

          if (!success) {
            print(
                '🔥 MatchCreationController: Error deduciendo ticket. Cancelando match...');
            await _matchService.cancelMatch(createdMatch.id);
            return null;
          }
        }

        _player.currentMatch.value = createdMatch;
        inviteCode.value = createdMatch.inviteCode ?? '';
        _player.subscribeToCurrentMatch(createdMatch.id);
        await _player.loadPlayerMatches();

        print('🔥 MatchCreationController: Flujo completado con éxito.');
        return createdMatch;
      }

      print('🔥 MatchCreationController: _matchService.createMatch retornó null');
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

      final match = await _matchService.joinMatchByCode(code, playerId);
      if (match != null) {
        _player.currentMatch.value = match;
        _player.subscribeToCurrentMatch(match.id);
        await _player.loadPlayerMatches();

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

      final match = await _matchService.joinMatch(matchId, playerId);
      if (match != null) {
        _player.currentMatch.value = match;
        _player.subscribeToCurrentMatch(match.id);

        await _player.loadAvailableMatchesToJoin();
        await _player.loadPlayerMatches();

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
    final String requiredTicketType =
        match.matchType == MatchType.oneVsOne ? 'singles' : 'doubles';

    if (needsTicket) {
      final ticketController = TicketController.instance;
      if (!ticketController.hasTickets(requiredTicketType)) {
        CustomToast.instance.showWarningToast(
          title: 'No tienes tickets',
          message:
              'Necesitas un ticket de ${requiredTicketType == "singles" ? "Singles (1v1)" : "Dobles (2v2)"} para jugar.',
        );
        return;
      }
    }

    Get.to(() => ReviewSummary(onConfirm: () async {
          final joinedMatch = await _matchService.joinMatch(match.id, playerId);
          if (joinedMatch != null) {
            if (needsTicket) {
              final success = await TicketController.instance
                  .useTicketForMatch(match.id, requiredTicketType);
              if (!success) {
                CustomToast.instance.showFailureToast(
                    title: 'Error', message: 'Error procesando el ticket.');
                return false;
              }
            }

            _player.currentMatch.value = joinedMatch;
            _player.subscribeToCurrentMatch(match.id);
            await _player.loadPlayerMatches();
            return true;
          }
          return false;
        }));
  }

  /// Reject an invitation (2v2 partner)
  Future<void> rejectInvitation(MatchModel match) async {
    try {
      final success = await _matchService.cancelMatch(match.id);
      if (success) {
        if (Get.isRegistered<TicketController>()) {
          final refundType =
              match.matchType == MatchType.oneVsOne ? 'singles' : 'doubles';
          await TicketController.instance
              .refundTicketForUser(match.id, match.player1Id, refundType);
        }

        _player.availableMatchesToJoin.removeWhere((m) => m.id == match.id);

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
    }
  }

  /// Cancel a match (with optimistic ticket refund)
  Future<bool> cancelMatch(String matchId) async {
    final match = _player.playerMatches.firstWhereOrNull((m) => m.id == matchId);
    final ticketController = Get.find<TicketController>();
    bool wasOptimistic = false;

    try {
      // Optimistic Update: Increment ticket balance immediately
      if (match != null) {
        if (match.matchType == MatchType.oneVsOne) {
          ticketController.singlesBalance.value++;
        } else {
          ticketController.doublesBalance.value++;
        }
        wasOptimistic = true;
      }

      await Supabase.instance.client.rpc(
        'cancel_match_and_refund',
        params: {
          'p_match_id': matchId,
          'p_user_id': currentUserId,
        },
      );

      _player.currentMatch.value = null;
      await _player.loadPlayerMatches();

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
    }
  }

  /// Confirm check-in for the current player
  Future<bool> confirmCheckIn(String matchId) async {
    final userId = currentUserId;
    if (userId == null) return false;

    try {
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
          message: 'No eres participante de este partido.',
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
        await _player.loadPlayerMatches();
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
}
