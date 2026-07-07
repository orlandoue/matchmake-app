import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/club_admin/services/club_admin_service.dart';
import 'package:orland_sports/controllers/auth_controller.dart';
import 'package:orland_sports/models/club_model.dart';
import 'package:orland_sports/models/court_model.dart';
import 'package:orland_sports/models/sport_model.dart';
import 'package:orland_sports/models/match_model.dart';
import 'package:orland_sports/utils/custom_toast.dart';

class ClubAdminController extends GetxController {
  static ClubAdminController get instance => Get.find<ClubAdminController>();

  final _service = ClubAdminService.instance;

  // Observables
  final RxBool isLoading = true.obs;
  final RxBool isCreatingCourt = false.obs;
  final RxBool isCreatingClub = false.obs;

  final Rx<ClubModel?> currentClub = Rx<ClubModel?>(null);
  bool get hasClub => currentClub.value != null;
  final RxList<CourtModel> myCourts = <CourtModel>[].obs;
  final RxInt totalMatchesPlayed = 0.obs;
  final RxList<SportModel> sports = <SportModel>[].obs;

  // KPI Observables
  final RxInt todayReservations = 0.obs;
  final RxInt weekReservations = 0.obs;
  final RxInt monthReservations = 0.obs;

  // Agenda Observables
  final Rx<DateTime> selectedAgendaDate = DateTime.now().obs;
  final RxList<MatchModel> dailyMatches = <MatchModel>[].obs;
  final RxBool isLoadingAgenda = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      final currentUser = AuthController.instance.currentUser.value;
      if (currentUser == null) {
        isLoading.value = false;
        return;
      }

      // 1. Get Club
      final club = await _service.getClubByOwnerId(currentUser.id);
      currentClub.value = club;

      if (club != null) {
        // 2. Fetch Courts
        await loadCourts();
        
        // 3. Load real metrics from service
        final metrics = await _service.getPlayedMatchesCount(club.id);
        totalMatchesPlayed.value = metrics;

        // 4. Load real dashboard KPIs from DB
        await _loadRealKpis(club.id);
      }

      // 4. Fetch Sports for the dropdown
      final allSports = await _service.getAllSports();
      sports.assignAll(allSports);

    } catch (e) {
      print('Error loading dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadRealKpis(String clubId) async {
    try {
      final kpis = await _service.getScheduledMatchesKpis(clubId);
      todayReservations.value = kpis['today'] ?? 0;
      weekReservations.value  = kpis['week']  ?? 0;
      monthReservations.value = kpis['month'] ?? 0;
    } catch (e) {
      // Fallback to zero — never show invented numbers
      todayReservations.value = 0;
      weekReservations.value  = 0;
      monthReservations.value = 0;
    }
  }

  Future<void> loadCourts() async {
    if (currentClub.value == null) return;
    final courts = await _service.getCourtsByClubId(currentClub.value!.id);
    myCourts.assignAll(courts);
    // After loading courts, also fetch agenda for the current date
    await fetchMatchesForDate(selectedAgendaDate.value);
  }

  Future<void> createCourt(String name, String sportId) async {
    if (currentClub.value == null) {
      CustomToast.instance.showFailureToast(
          title: 'Error', message: 'No se encontró tu recinto activo.');
      return;
    }

    if (name.trim().isEmpty) {
      CustomToast.instance.showFailureToast(
          title: 'Error', message: 'El nombre de la cancha no puede estar vacío.');
      return;
    }

    if (sportId.isEmpty) {
      CustomToast.instance.showFailureToast(
          title: 'Error', message: 'Debes seleccionar un deporte.');
      return;
    }

    isCreatingCourt.value = true;
    try {
      final success = await _service.createCourt(
          name.trim(), currentClub.value!.id, sportId);
      if (success) {
        CustomToast.instance.showSuccessToast(
            title: 'Éxito', message: 'Cancha agregada correctamente.');
        Get.back(); // Cierra el bottom sheet
        await loadCourts(); // Refresca las canchas
      } else {
        CustomToast.instance.showFailureToast(
            title: 'Error', message: 'Ocurrió un error al crear la cancha.');
      }
    } finally {
      isCreatingCourt.value = false;
    }
  }

  int get totalActiveCourts => myCourts.where((c) => c.isActive).length;

  // --- Agenda Methods ---

  Future<void> setAgendaDate(DateTime date) async {
    selectedAgendaDate.value = date;
    await fetchMatchesForDate(date);
  }

  Future<void> fetchMatchesForDate(DateTime date) async {
    if (myCourts.isEmpty) return;
    final courtIds = myCourts.map((c) => c.id).toList();
    
    isLoadingAgenda.value = true;
    try {
      final matches = await _service.getMatchesForDate(courtIds, date);
      dailyMatches.assignAll(matches);
    } finally {
      isLoadingAgenda.value = false;
    }
  }

  Future<void> blockCourtTime(String courtId, String time) async {
    isLoadingAgenda.value = true;
    try {
      final success = await _service.createManualReservation(
          courtId, selectedAgendaDate.value, time);
      if (success) {
        CustomToast.instance.showSuccessToast(
            title: 'Bloqueado', message: 'Se ha bloqueado la cancha exitosamente.');
        await fetchMatchesForDate(selectedAgendaDate.value); // refresh grid
      } else {
        CustomToast.instance.showFailureToast(
            title: 'Error', message: 'Ocurrió un error al bloquear el turno.');
      }
    } finally {
      isLoadingAgenda.value = false;
    }
  }

  Future<void> unblockCourt(String matchId) async {
    isLoadingAgenda.value = true;
    try {
      final success = await _service.deleteMatch(matchId);
      if (success) {
        CustomToast.instance.showSuccessToast(
            title: 'Desbloqueado', message: 'El turno ha sido liberado.');
        await fetchMatchesForDate(selectedAgendaDate.value); // refresh grid
      } else {
        CustomToast.instance.showFailureToast(
            title: 'Error', message: 'No se pudo desbloquear el turno.');
      }
    } finally {
      isLoadingAgenda.value = false;
    }
  }

  // --- Onboarding (Create Club) ---
  Future<void> createClub(String name, String phone, String address, double lat, double lng) async {
    final currentUser = AuthController.instance.currentUser.value;
    if (currentUser == null) return;
    
    if (name.trim().isEmpty) {
      CustomToast.instance.showFailureToast(title: 'Error', message: 'Ingresa el nombre del club');
      return;
    }

    isCreatingClub.value = true;
    try {
      final newClub = await _service.createClub(name.trim(), phone.trim(), address.trim(), lat, lng, currentUser.id);
      if (newClub != null) {
        currentClub.value = newClub;
        CustomToast.instance.showSuccessToast(title: 'Éxito', message: '¡Tu club ha sido creado!');
        Get.back(); // close bottom sheet
        await loadDashboardData(); // Refresh UI to fetch dashboard properly
      } else {
        CustomToast.instance.showFailureToast(title: 'Error', message: 'No se pudo crear el club.');
      }
    } finally {
      isCreatingClub.value = false;
    }
  }

  // --- Update Club Profile ---
  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (currentClub.value == null) return;
    try {
      final success = await _service.updateClubProfile(currentClub.value!.id, data);
      if (success) {
        CustomToast.instance.showSuccessToast(title: 'Actualizado', message: 'Perfil guardado con éxito');
        await loadDashboardData(); // Refresh club info
      } else {
        CustomToast.instance.showFailureToast(title: 'Error', message: 'Error al actualizar el perfil');
      }
    } catch (e) {
      CustomToast.instance.showFailureToast(title: 'Error', message: 'Ocurrió un problema: $e');
    }
  }
}
