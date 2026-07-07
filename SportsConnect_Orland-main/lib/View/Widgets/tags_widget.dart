


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';

class TagsWidget extends StatelessWidget {
  final String tag;
  final Color? bgColor, textColor, borderColor, sbgColor, sBorderColor;
  final double? vpad, hpad, radius, textSize;
  final bool hasIcon;

  TagsWidget(
    this.tag, {
    Key? key,
    this.bgColor,
    this.textColor,
    this.borderColor,
    this.vpad,
    this.hpad,
    this.radius,
    this.textSize,
    this.hasIcon = true,
    this.sbgColor,
    this.sBorderColor,
  }) : super(key: key);

  final RxBool isSelected = false.obs;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return GestureDetector(
        onTap: () {
          isSelected.value = !isSelected.value;
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: hpad ?? 12,
            vertical: vpad ?? 7,
          ),
          decoration: BoxDecoration(
            color: isSelected.value
                ? sbgColor ?? kpurple1
                : bgColor ?? Color(0xffF1EBFF),
            borderRadius: BorderRadius.circular(radius ?? 4),
            border: Border.all(
              color: isSelected.value
                  ? sBorderColor ?? ktransparent
                  : borderColor ?? ktransparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasIcon)
                Icon(Icons.close_rounded, size: 14, color: Colors.white),
              MyText(
                paddingLeft: isSelected.value ? 4 : 0,
                text: tag,
                size: textSize ?? 14,
                weight: FontWeight.w500,
                color: isSelected.value ? kwhite : textColor ?? kblack,
              ),
            ],
          ),
        ),
      );
    });
  }
}