import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:orland_sports/models/court_model.dart';

/// Controller for Google Maps functionality
/// Handles map configuration, custom markers, and map utilities
class MapsController extends GetxController {
  static MapsController get instance => Get.find<MapsController>();

  // Custom marker icons
  BitmapDescriptor? _defaultMarkerIcon;
  BitmapDescriptor? _selectedMarkerIcon;
  BitmapDescriptor? _courtMarkerIcon;

  // Map configuration
  final RxBool isMapLoading = true.obs;
  final RxBool markersLoaded = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCustomMarkers();
  }

  /// Load custom marker icons
  Future<void> _loadCustomMarkers() async {
    try {
      // Using default markers with custom hues for now
      // You can replace these with custom icons from assets
      _defaultMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueRed,
      );
      _selectedMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueViolet,
      );
      _courtMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      );

      markersLoaded.value = true;
    } catch (e) {
      debugPrint('Error loading custom markers: $e');
      markersLoaded.value = true; // Continue with default markers
    }
  }

  /// Get the default marker icon
  BitmapDescriptor get defaultMarkerIcon =>
      _defaultMarkerIcon ?? BitmapDescriptor.defaultMarker;

  /// Get the selected marker icon
  BitmapDescriptor get selectedMarkerIcon =>
      _selectedMarkerIcon ??
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);

  /// Get the court marker icon
  BitmapDescriptor get courtMarkerIcon =>
      _courtMarkerIcon ??
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);

  /// Create a marker for a court
  Marker createCourtMarker({
    required CourtModel court,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Marker(
      markerId: MarkerId(court.id),
      position: LatLng(court.latitude, court.longitude),
      icon: isSelected ? selectedMarkerIcon : courtMarkerIcon,
      infoWindow: InfoWindow(
        title: court.name,
        snippet: court.address ?? 'No address available',
      ),
      onTap: onTap,
    );
  }

  /// Create markers for a list of courts
  Set<Marker> createCourtsMarkers({
    required List<CourtModel> courts,
    String? selectedCourtId,
    required Function(CourtModel) onCourtTap,
  }) {
    return courts.map((court) {
      return createCourtMarker(
        court: court,
        isSelected: court.id == selectedCourtId,
        onTap: () => onCourtTap(court),
      );
    }).toSet();
  }

  /// Get default map style (light mode)
  String get lightMapStyle => '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#f5f5f5"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#f5f5f5"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#eeeeee"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#e5e5e5"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#c9c9c9"}]
  }
]
''';

  /// Get dark map style
  String get darkMapStyle => '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#212121"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#212121"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#1e1e1e"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#2c2c2c"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#000000"}]
  }
]
''';

  /// Default camera position — Santiago de Chile (fallback when GPS is unavailable)
  CameraPosition get defaultCameraPosition => const CameraPosition(
        target: LatLng(-33.4569, -70.6483),
        zoom: 12.0,
      );

  /// Map padding
  EdgeInsets get mapPadding => const EdgeInsets.only(
        bottom: 150,
        top: 100,
      );
}
