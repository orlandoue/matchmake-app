import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:orland_sports/const/appColors.dart';

class CustomToast {
  // Private constructor
  CustomToast._privateConstructor();

  // Singleton instance variable
  static CustomToast? _instance;

  // Getter to access the singleton instance
  static CustomToast get instance {
    _instance ??= CustomToast._privateConstructor();
    return _instance!;
  }

  /// Show success toast
  void showSuccessToast({
    required String title,
    required String message,
    int duration = 3,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: duration,
      backgroundColor: Colors.green.shade700,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  /// Show failure/error toast
  void showFailureToast({
    required String title,
    required String message,
    int duration = 3,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: duration,
      backgroundColor: Colors.red.shade700,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  /// Show warning toast
  void showWarningToast({
    required String title,
    required String message,
    int duration = 3,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: duration,
      backgroundColor: Colors.orange.shade700,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  /// Show generic toast
  void showToast({required String message}) {
    Fluttertoast.showToast(
      msg: message,
      fontSize: 14,
      backgroundColor: kpurple1,
      textColor: kpurple3,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  /// Dismiss any open dialog and show error toast
  void dismissAndShowError(String message) async {
    // Dismiss any open dialogs
    if (Get.isDialogOpen ?? false) {
      Navigator.pop(Get.context!);
    }

    await Future.delayed(const Duration(milliseconds: 100));

    showFailureToast(
      title: 'Error',
      message: message,
    );
  }
}
