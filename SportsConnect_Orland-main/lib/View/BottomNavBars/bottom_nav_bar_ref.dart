import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:orland_sports/View/Screens/Referee/Home/home.dart';
import 'package:orland_sports/View/Screens/Referee/Matches/matches_main.dart';
import 'package:orland_sports/View/Screens/Referee/Payment/payout.dart';
import 'package:orland_sports/View/Screens/Referee/Profile/Profile.dart';
import 'package:orland_sports/View/Widgets/CommonImageView.dart';
import 'package:orland_sports/const/appColors.dart';
import 'package:orland_sports/const/app_fonts.dart';

import '../../generated/assets.dart';

class BottomNavBarReferre extends StatefulWidget {
  @override
  State<BottomNavBarReferre> createState() => _BottomNavBarReferreState();
}

class _BottomNavBarReferreState extends State<BottomNavBarReferre> {
  late List<Map<String, dynamic>> items;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    updateItems();
  }

  void updateItems() {
    items = [
      {
        'image': currentIndex == 0
            ? Assets.imagesHomefilled
            : Assets.imagesHomeunfilled,
        'label': 'Inicio',
      },
      {
        'image': currentIndex == 1
            ? Assets.imagesMatchfilled
            : Assets.imagesMatchunfilled,
        'label': 'Partidos',
      },
 
      {
        'image': currentIndex == 2
            ? Assets.imagesPaymentfilled
            : Assets.imagesPaymentunfilled,
        'label': 'Pagos',
      },
      {
        'image': currentIndex == 3
            ? Assets.imagesProfilefilled
            : Assets.imagesProfileunfilled,
        'label': 'Perfil',
      },
    ];
  }

  final List<Widget> screens = [
    ReferreHome(),
    MatchesMain(),
 ReferrePayout(),
    ReferreProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
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
          child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          onTap: (index) {
            setState(() {
              currentIndex = index;
              log(currentIndex.toString());
              updateItems(); // Update items when index changes
            });
          },
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
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
        ),
      ),
      ),
    );
  }
}

///////////////////////////

