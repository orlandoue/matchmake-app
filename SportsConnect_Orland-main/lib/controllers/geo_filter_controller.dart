import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:orland_sports/controllers/match_controller.dart';
import 'package:orland_sports/models/club_model.dart';
import 'package:orland_sports/services/club_service.dart';

/// Controller for the GeoFilterScreen.
/// Manages GPS location, radius slider, and multi-club selection.
/// Map-related logic has been removed — this screen is list-only.
class GeoFilterController extends GetxController {
  static GeoFilterController get instance => Get.find<GeoFilterController>();

  // ── Services ──────────────────────────────────────────────────────────────
  final _clubService = CourtService.instance;

  // ── Observables: State ────────────────────────────────────────────────────
  final RxBool isLoading = false.obs;
  final RxBool isLocating = false.obs;
  final RxString errorMessage = ''.obs;

  // ── Observables: Location ─────────────────────────────────────────────────
  /// Current user position as [lat, lng]. Defaults to Santiago Centro.
  final RxDouble userLat = (-33.4569).obs;
  final RxDouble userLng = (-70.6483).obs;

  // ── Observables: Radius ───────────────────────────────────────────────────
  final RxDouble radiusKm = 5.0.obs;
  static const double kMinRadius = 1.0;
  static const double kMaxRadius = 20.0;

  // ── Observables: Clubs ────────────────────────────────────────────────────
  final RxList<ClubModel> nearbyClubs = <ClubModel>[].obs;
  final RxSet<String> selectedClubIds = <String>{}.obs;

  // ── Debounce timer for slider ─────────────────────────────────────────────
  Timer? _radiusDebounce;

  @override
  void onInit() {
    super.onInit();
    _requestLocationAndLoad();

    // React to radius changes with a small debounce
    ever(radiusKm, (_) {
      _radiusDebounce?.cancel();
      _radiusDebounce = Timer(const Duration(milliseconds: 600), loadNearbyClubs);
    });
  }

  @override
  void onClose() {
    _radiusDebounce?.cancel();
    super.onClose();
  }

  // ── Initialization ────────────────────────────────────────────────────────

  /// Request location permission and obtain GPS coordinates.
  /// On failure or denial, keeps the Santiago de Chile fallback.
  Future<void> _requestLocationAndLoad() async {
    isLocating.value = true;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('GeoFilter: Location services disabled, using fallback.');
        await loadNearbyClubs();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('GeoFilter: Permission denied, using fallback (Santiago).');
          await loadNearbyClubs();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('GeoFilter: Permission permanently denied, using fallback.');
        await loadNearbyClubs();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      userLat.value = position.latitude;
      userLng.value = position.longitude;
      debugPrint('GeoFilter: GPS resolved → ${position.latitude}, ${position.longitude}');

      await loadNearbyClubs();
    } catch (e) {
      debugPrint('GeoFilter: Error getting location: $e');
      await loadNearbyClubs(); // Use default Santiago position
    } finally {
      isLocating.value = false;
    }
  }

  // ── Public Methods ────────────────────────────────────────────────────────

  /// Re-request location and reload clubs.
  Future<void> relocateUser() async {
    await _requestLocationAndLoad();
  }

  /// Load clubs from the PostGIS RPC within the current radius.
  /// - Sends coordinates as WKT: 'POINT(lng lat)'
  /// - Converts radiusKm → meters for the DB function
  /// - Passes sport_id from MatchController (optional filter)
  Future<void> loadNearbyClubs() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      // Resolve the selected sport UUID (null = no sport filter)
      String? sportId;
      if (Get.isRegistered<MatchController>()) {
        final matchCtrl = Get.find<MatchController>();
        final sportName = matchCtrl.selectedSport.value;
        sportId = matchCtrl.sportUUIDMap[sportName];
        debugPrint('GeoFilter: sport="$sportName" → uuid=$sportId');
      }

      final clubs = await _clubService.getClubsInRange(
        lat: userLat.value,
        lng: userLng.value,
        radiusKm: radiusKm.value,
        sportId: sportId,
      );
      nearbyClubs.assignAll(clubs);
      debugPrint('GeoFilter: ${clubs.length} clubs found within ${radiusKm.value} km.');
    } catch (e) {
      errorMessage.value = 'Error cargando clubes: $e';
      debugPrint('GeoFilter: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle selection of a club by ID.
  void toggleClubSelection(String clubId) {
    if (selectedClubIds.contains(clubId)) {
      selectedClubIds.remove(clubId);
    } else {
      selectedClubIds.add(clubId);
    }
  }

  /// True if the "Confirmar Recintos" button should be enabled.
  bool get canSearch => selectedClubIds.isNotEmpty;

  /// Return selected clubs as a sorted list (same order as nearbyClubs).
  List<ClubModel> get selectedClubs =>
      nearbyClubs.where((c) => selectedClubIds.contains(c.id)).toList();

  // ── Slider handling ───────────────────────────────────────────────────────

  void onRadiusChanged(double value) {
    radiusKm.value = value;
  }
}
