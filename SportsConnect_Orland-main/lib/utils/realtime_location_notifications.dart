import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class RealtimeLocationNotification {
  static void showLocationUpdateNotification({
    required String businessName,
    required double lat,
    required double lng,
  }) {
    Fluttertoast.showToast(
      msg:
          '$businessName moved to Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green.shade700,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  static void showBusinessNearbyAlert({
    required String businessName,
    required double distance,
  }) {
    Fluttertoast.showToast(
      msg: '$businessName is ${distance.toStringAsFixed(1)}km away',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.blue.shade700,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  static void showBusinessMovedAway({
    required String businessName,
  }) {
    Fluttertoast.showToast(
      msg: '$businessName moved out of your area',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.orange.shade700,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }
}
