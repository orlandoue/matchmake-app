import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/View/Widgets/myText.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/generated/assets.dart';


/// MODEL FOR MENU ITEMS
class CustomMenuOption {
  final String? title;
  final Color? txtColor;
  final VoidCallback? onTap;
  final String? iconPath; // optional image path
  final Widget? iconWidget; // optional widget icon

  CustomMenuOption({
    this.title,
    this.onTap,
    this.txtColor,
    this.iconPath,
    this.iconWidget,
  });
}

class CustomPopupMenuButton extends StatelessWidget {
  final List<CustomMenuOption> options;

  final String? iconPath;
  final double? iconHeight;
  final double? iconWidth;
  final Color? iconColor;

  final Color backgroundColor;
  final Color shadowColor;
  final EdgeInsetsGeometry menuPadding;
  final Offset offset;
  final PopupMenuPosition position;
  final EdgeInsetsGeometry padding;
  final Color? surfaceTintColor;
  final AnimationStyle? popUpAnimationStyle;

  const CustomPopupMenuButton({
    super.key,
    required this.options,
    this.iconPath = Assets.imagesBackicon,
    this.iconHeight = 24,
    this.iconWidth = 24,
    this.iconColor,
    this.backgroundColor = kgrey3,
    this.shadowColor = kgrey2,
    this.menuPadding = const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
    this.offset = const Offset(40, -15),
    this.position = PopupMenuPosition.under,
    this.padding = const EdgeInsets.all(0),
    this.surfaceTintColor = const Color.fromARGB(155, 194, 192, 192),
    this.popUpAnimationStyle,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      menuPadding: menuPadding,
      popUpAnimationStyle: popUpAnimationStyle,
      offset: offset,
      position: position,
      splashRadius: 22,
      shadowColor: shadowColor,
      padding: padding,
      surfaceTintColor: surfaceTintColor,

      icon: iconPath != null
          ? CommonImageView(
              imagePath: iconPath!,
              height: iconHeight,
              width: iconWidth,
              color: iconColor,
            )
          : null,

      onSelected: (index) {
        options[index].onTap?.call();
      },

      itemBuilder: (_) => List.generate(options.length, (index) {
        final item = options[index];

        return PopupMenuItem<int>(
          value: index,
          padding: EdgeInsets.all(8),
          child:item.title!=null?SizedBox(
            width: 90,
            child: MyText(text: item.title??'', color: item.txtColor ?? kblack,size: 14,textAlign: TextAlign.center,)): SizedBox(
            width: 80,
            child: Row(
              spacing: item.iconPath != null || item.iconWidget != null
                  ? 10
                  : 0,
              //  mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //Expanded(child: MyText(text: item.title??'', color: item.txtColor ?? kblack,size: 14,)),
          
                /// SHOW ICON ONLY IF AVAILABLE
                if (item.iconWidget != null) item.iconWidget!,
                if (item.iconWidget == null && item.iconPath != null)
                  Image.asset( item.iconPath!, height: 20),
              ],
            ),
          ),
        );
      }),
    );
  }
}
