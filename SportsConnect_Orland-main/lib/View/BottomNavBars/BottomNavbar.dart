import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/View/Screens/Users/History/History.dart';
import 'package:orland_sports/View/Screens/Users/Home/home.dart';
import 'package:orland_sports/View/Screens/Users/Profile/Profile.dart';
import 'package:orland_sports/View/Screens/Users/Search/Search.dart';
import 'package:orland_sports/View/Screens/Users/Store/buy_tickets_screen.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/const/app_fonts.dart';

import '../../generated/assets.dart';

class BottomNavBarController extends GetxController {
  var currentIndex = 0.obs;

  void changeTabIndex(int index) {
    currentIndex.value = index;
  }
}

class BottomNavBar extends StatefulWidget {
  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  final BottomNavBarController navController = Get.put(BottomNavBarController());
  late List<Map<String, dynamic>> items;

  @override
  void initState() {
    super.initState();
    updateItems();
    // Listen to changes in the controller to update the items (images)
    ever(navController.currentIndex, (_) {
      setState(() {
        updateItems();
      });
    });
  }

  void updateItems() {
    items = [
      {
        'image': navController.currentIndex.value == 0
            ? Assets.imagesHomefilled
            : Assets.imagesHomeunfilled,
        'label': 'Inicio',
      },
      {
        'image': navController.currentIndex.value == 1
            ? Assets.imagesExplorefilled
            : Assets.imagesExploreunfilled,
        'label': 'Explorar',
      },
      {
        'image': navController.currentIndex.value == 2
            ? Assets.imagesStorefilled
            : Assets.imagesStoreunfilled,
        'label': 'Tienda',
      },
      {
        'image': navController.currentIndex.value == 3
            ? Assets.imagesHistoryfilled
            : Assets.imagesHistoryunfilled,
        'label': 'Historial',
      },
      {
        'image': navController.currentIndex.value == 4
            ? Assets.imagesProfilefilled
            : Assets.imagesProfileunfilled,
        'label': 'Perfil',
      },
    ];
  }

  final List<Widget> screens = [
    MyHome(),
    Search(),
    BuyTicketsScreen(),
    History(),
    Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => screens[navController.currentIndex.value]),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.all(0),
          height: 62,
          decoration: BoxDecoration(
            color: kwhite,
            // border: Border.all(color: kgrey1),
            boxShadow: [
              BoxShadow(
                color: kgrey1.withOpacity(0.3),
                offset: const Offset(0, 2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Obx(() => BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            onTap: (index) {
              navController.changeTabIndex(index);
              log(navController.currentIndex.value.toString());
            },
            type: BottomNavigationBarType.fixed,
            currentIndex: navController.currentIndex.value,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: TextStyle(
              fontFamily: AppFonts.boston,
              color: kpurple1,
              fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(
            fontFamily: AppFonts.boston,
            color: kgrey2,
          ),
          selectedItemColor: kpurple1,
          unselectedItemColor: kgrey1,
          items: List.generate(
            items.length,
            (index) {
              return BottomNavigationBarItem(
                tooltip: 'ss',
                activeIcon: CommonImageView(
                  imagePath: items[index]['image'],
                  width: 22,
                ),
                icon: CommonImageView(
                  imagePath: items[index]['image'],
                  width: 22,
                ),
                label: items[index]['label'],
              );
            },
          ),
          )),
        ),
      ),
    );
  }
}

///////////////////////////
