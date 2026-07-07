import 'package:flutter/material.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/const/app_fonts.dart';
import 'package:pinput/pinput.dart';

class MyPinCode extends StatelessWidget {
  final Function(String) onChanged;
  final Function(String) onCompleted;
  final Color? color;
  final TextEditingController? controller;
  final int length;

  const MyPinCode({
    super.key,
    required this.onChanged,
    required this.onCompleted,
    this.color,
    this.controller,
    this.length = 6,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 60,
      margin: const EdgeInsets.all(5),
      textStyle: TextStyle(
        fontSize: 20,
        color: color ?? kblack,
        fontWeight: FontWeight.w600,
        fontFamily: AppFonts.boston,
      ),
      decoration: BoxDecoration(
        color: kwhite.withOpacity(0.1),
        border: Border.all(color: kgrey2),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: kpurple1.withOpacity(0.09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color ?? kpurple1,
        ),
      ),
    );

    return Pinput(
      length: length,
      controller: controller,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      submittedPinTheme: defaultPinTheme.copyWith(
        decoration: BoxDecoration(
          color: kpurple1.withOpacity(0.09),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color ?? kpurple1,
          ),
        ),
      ),
      onChanged: onChanged,
      onCompleted: onCompleted,
    );
  }
}
