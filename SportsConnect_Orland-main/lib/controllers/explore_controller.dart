import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orland_sports/models/club_model.dart';
import 'package:orland_sports/models/court_model.dart';
import 'package:orland_sports/services/club_service.dart';

/// Controller for the Explore/Search screen
/// Handles map interactions, court loading, filtering, and marker management
class ExploreController extends GetxController {
  static ExploreController get instance => Get.find<ExploreController>();

  // Services
  final _courtService = CourtService.instance;

  // Google Maps Controller
  Completer<GoogleMapController>? mapController;

  // Observables - Loading states
  final RxBool isLoading = false.obs;
  final RxBool isMapReady = false.obs;
  final RxBool isSearching = false.obs;

  // Observables - Data
  final RxList<CourtModel> allCourts = <CourtModel>[].obs;
  final RxList<CourtModel> filteredCourts = <CourtModel>[].obs;
  final RxList<ClubModel> nearbyClubs = <ClubModel>[].obs;
  final Rx<CourtModel?> selectedCourt = Rx<CourtModel?>(null);

  // Observables - Map
  final RxSet<Marker> markers = <Marker>{}.obs;
  final Rx<LatLng> currentPosition =
      const LatLng(-33.4569, -70.6483).obs; // Default: Santiago de Chile (fallback GPS)
  final RxDouble currentZoom = 12.0.obs;

  // Observables - Filters
  final RxString searchQuery = ''.obs;
  final RxDouble radiusInKm = 15.0.obs;
  final RxDouble minRadius = 0.0.obs;
  final RxDouble maxRadius = 30.0.obs;

  // Observables - Error handling
  final RxString errorMessage = ''.obs;
  final RxBool hasError = false.obs;

  // Text controller for search
  final TextEditingController searchController = TextEditingController();

  // Debounce timer for search
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    _initializeExplore();

    // Listen to search query changes
    ever(searchQuery, (_) => _filterCourts());
  }

  @override
  void onClose() {
    searchController.dispose();
    _searchDebounce?.cancel();
    super.onClose();
  }

  /// Initialize: resolve GPS first, then load clubs at the real position.
  Future<void> _initializeExplore() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm != LocationPermission.denied &&
            perm != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );
          currentPosition.value = LatLng(pos.latitude, pos.longitude);
          debugPrint('Explore: GPS resolved -> ${pos.latitude}, ${pos.longitude}');
        }
      }
    } catch (e) {
      debugPrint('Explore: GPS error, using Santiago fallback. $e');
    }
    // Load clubs at resolved (or fallback) position
    await loadCourts();
  }

  /// Initialize the Google Maps controller
  void onMapCreated(GoogleMapController controller) {
    if (mapController == null || !mapController!.isCompleted) {
      mapController = Completer<GoogleMapController>();
      mapController!.complete(controller);
      isMapReady.value = true;
    }
  }

  // ==================== LOADING METHODS ====================

  /// Load nearby clubs using the PostGIS RPC (replaces old getActiveCourts).
  /// Uses the user's current GPS position and a 15km default radius.
  /// sport_id is null so ALL sports are returned for the Explore tab.
  Future<void> loadCourts() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final lat = currentPosition.value.latitude;
      final lng = currentPosition.value.longitude;

      final clubs = await _courtService.getClubsInRange(
        lat: lat,
        lng: lng,
        radiusKm: radiusInKm.value,
        sportId: null, // Show all sports on Explore tab
      );

      nearbyClubs.assignAll(clubs);

      // Convert ClubModel -> CourtModel for legacy UI compatibility
      final asCourts = clubs.map((c) => CourtModel(
        id: c.id,
        name: c.name,
        address: c.address,
        latitude: c.lat,
        longitude: c.lng,
        imageUrl: c.imageUrl,
        isActive: c.isActive,
        isIndoor: false,
      )).toList();

      allCourts.assignAll(asCourts);
      filteredCourts.assignAll(asCourts);
      _generateMarkers();

      debugPrint('Explore: loaded ${clubs.length} clubs within ${radiusInKm.value} km.');
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Error cargando clubes: $e';
      debugPrint('ExploreController: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh courts data
  Future<void> refreshCourts() async {
    await loadCourts();
  }

  // ==================== SEARCH & FILTER METHODS ====================

  /// Handle search input with debounce
  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      searchQuery.value = value;
    });
  }

  /// Filter courts based on search query and radius
  void _filterCourts() {
    if (searchQuery.value.isEmpty) {
      filteredCourts.assignAll(allCourts);
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredCourts.assignAll(allCourts.where((court) {
        final nameMatch = court.name.toLowerCase().contains(query);
        final addressMatch =
            court.address?.toLowerCase().contains(query) ?? false;
        final sportMatch = court.sports
                ?.any((sport) => sport.name.toLowerCase().contains(query)) ??
            false;
        return nameMatch || addressMatch || sportMatch;
      }).toList());
    }
    _generateMarkers();
  }

  /// Apply radius filter
  void applyRadiusFilter(double minKm, double maxKm) {
    minRadius.value = minKm;
    maxRadius.value = maxKm;
    radiusInKm.value = maxKm;

    // Filter courts by distance from current position
    final filtered = allCourts.where((court) {
      final distance = _calculateDistance(
        currentPosition.value.latitude,
        currentPosition.value.longitude,
        court.latitude,
        court.longitude,
      );
      return distance >= minKm && distance <= maxKm;
    }).toList();

    filteredCourts.assignAll(filtered);
    _generateMarkers();
  }

  /// Clear all filters
  void clearFilters() {
    searchQuery.value = '';
    searchController.clear();
    radiusInKm.value = 15.0;
    minRadius.value = 0.0;
    maxRadius.value = 30.0;
    filteredCourts.assignAll(allCourts);
    _generateMarkers();
  }

  // ==================== MAP METHODS ====================

  /// Generate markers for filtered courts
  void _generateMarkers() {
    final Set<Marker> newMarkers = {};

    for (final court in filteredCourts) {
      final marker = Marker(
        markerId: MarkerId(court.id),
        position: LatLng(court.latitude, court.longitude),
        infoWindow: InfoWindow(
          title: court.name,
          snippet: court.address ?? '',
          onTap: () => selectCourt(court),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          selectedCourt.value?.id == court.id
              ? BitmapDescriptor.hueViolet
              : BitmapDescriptor.hueRed,
        ),
        onTap: () => selectCourt(court),
      );
      newMarkers.add(marker);
    }

    markers.assignAll(newMarkers);
  }

  /// Select a court and center map on it
  Future<void> selectCourt(CourtModel court) async {
    selectedCourt.value = court;
    _generateMarkers(); // Update marker colors

    // Animate camera to selected court
    await animateToLocation(LatLng(court.latitude, court.longitude));
  }

  /// Clear selected court
  void clearSelectedCourt() {
    selectedCourt.value = null;
    _generateMarkers();
  }

  /// Animate camera to a specific location
  Future<void> animateToLocation(LatLng location, {double? zoom}) async {
    if (mapController != null && mapController!.isCompleted) {
      final controller = await mapController!.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: location,
            zoom: zoom ?? 14.0,
          ),
        ),
      );
    }
  }

  /// Update current map position
  void onCameraMove(CameraPosition position) {
    currentPosition.value = position.target;
    currentZoom.value = position.zoom;
  }

  /// Center map on a specific court
  Future<void> centerOnCourt(CourtModel court) async {
    await selectCourt(court);
  }

  /// Fit all markers in view
  Future<void> fitAllMarkers() async {
    if (filteredCourts.isEmpty) return;

    if (mapController != null && mapController!.isCompleted) {
      final controller = await mapController!.future;

      double minLat = filteredCourts.first.latitude;
      double maxLat = filteredCourts.first.latitude;
      double minLng = filteredCourts.first.longitude;
      double maxLng = filteredCourts.first.longitude;

      for (final court in filteredCourts) {
        if (court.latitude < minLat) minLat = court.latitude;
        if (court.latitude > maxLat) maxLat = court.latitude;
        if (court.longitude < minLng) minLng = court.longitude;
        if (court.longitude > maxLng) maxLng = court.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Calculate distance between two coordinates in kilometers (Haversine formula)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);

    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * 3.141592653589793 / 180;
  double _sin(double x) => _taylor_sin(x);
  double _cos(double x) => _taylor_sin(x + 1.5707963267948966);
  double _sqrt(double x) => _babylonianSqrt(x);
  double _atan2(double y, double x) => _approxAtan2(y, x);

  // Taylor series approximation for sin
  double _taylor_sin(double x) {
    // Normalize x to [-π, π]
    while (x > 3.141592653589793) x -= 6.283185307179586;
    while (x < -3.141592653589793) x += 6.283185307179586;

    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  // Babylonian method for square root
  double _babylonianSqrt(double n) {
    if (n < 0) return double.nan;
    if (n == 0) return 0;
    double x = n;
    double y = 1;
    const double e = 0.000001;
    while (x - y > e) {
      x = (x + y) / 2;
      y = n / x;
    }
    return x;
  }

  // Approximation for atan2
  double _approxAtan2(double y, double x) {
    if (x == 0) {
      if (y > 0) return 1.5707963267948966;
      if (y < 0) return -1.5707963267948966;
      return 0;
    }
    double atan = _approxAtan(y / x);
    if (x < 0) {
      if (y >= 0) return atan + 3.141592653589793;
      return atan - 3.141592653589793;
    }
    return atan;
  }

  double _approxAtan(double x) {
    if (x > 1) return 1.5707963267948966 - _approxAtan(1 / x);
    if (x < -1) return -1.5707963267948966 - _approxAtan(1 / x);
    return x - (x * x * x) / 3 + (x * x * x * x * x) / 5;
  }

  /// Get distance string for a court from current position
  String getDistanceString(CourtModel court) {
    final distance = _calculateDistance(
      currentPosition.value.latitude,
      currentPosition.value.longitude,
      court.latitude,
      court.longitude,
    );

    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m away';
    }
    return '${distance.toStringAsFixed(1)} km away';
  }

  /// Get court by ID
  CourtModel? getCourtById(String courtId) {
    return allCourts.firstWhereOrNull((court) => court.id == courtId);
  }
}
