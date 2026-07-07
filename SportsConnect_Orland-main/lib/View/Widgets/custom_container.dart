import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:orland_sports/const/appColors.dart';


class CustomeContainer extends StatelessWidget {
  final Widget? widget;
  final Color? color, borderColor, shadowColor;
  final double? radius,
      vpad,
      hpad,
      mtop,
      height,
      width,
      mbott,
      borderWidth,
      mleft,
      mrigth;
  final bool hasShadow;
  final bool? hasGrad;
  final LinearGradient? gradColor;
  final BorderRadius? borderRadius;
  const CustomeContainer({
    super.key,
    this.widget,
    this.color,
    this.borderColor,
    this.shadowColor,
    this.radius,
    this.vpad,
    this.hpad,
    this.mtop,
    this.mbott,
    this.height,
    this.width,
    this.hasShadow = false,
    this.borderWidth,
    this.mleft,
    this.mrigth,
    this.borderRadius,
    this.hasGrad = false,
    this.gradColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.none,
      height: height,
      width: width,
      margin: EdgeInsets.only(
        top: mtop ?? 0,
        bottom: mbott ?? 0,
        left: mleft ?? 0,
        right: mrigth ?? 0,
      ),
      padding: EdgeInsets.symmetric(
        vertical: vpad ?? 16,
        horizontal: hpad ?? 18,
      ),
      decoration: BoxDecoration(
        color: hasGrad == false ? color : null,
        gradient: hasGrad == true ? gradColor : null,
        borderRadius: borderRadius ?? BorderRadius.circular(radius ?? 12),
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: borderWidth ?? 1,
        ),
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: kgrey1.withOpacity(0.1),
                  blurRadius: 5,
                  spreadRadius: -2,
                  offset: Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: widget,
    );
  }
}
