import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orland_sports/club_admin/controllers/club_admin_controller.dart';
import 'package:orland_sports/club_admin/controllers/club_wallet_controller.dart';
import 'package:orland_sports/club_admin/screens/club_courts_screen.dart';
import 'package:orland_sports/club_admin/screens/club_agenda_screen.dart';
import 'package:orland_sports/club_admin/screens/club_profile_screen.dart';
import 'package:orland_sports/club_admin/screens/club_wallet_screen.dart';

class ClubBottomNavScreen extends StatefulWidget {
  const ClubBottomNavScreen({Key? key}) : super(key: key);

  @override
  State<ClubBottomNavScreen> createState() => _ClubBottomNavScreenState();
}

class _ClubBottomNavScreenState extends State<ClubBottomNavScreen> {
  int _currentIndex = 0;

  // Screens are defined as a getter so they are never constructed before
  // initState runs and both controllers are guaranteed to be registered.
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // 1. Register ClubAdminController first — WalletController depends on it.
    if (!Get.isRegistered<ClubAdminController>()) {
      Get.put(ClubAdminController());
    }

    // 2. Register ClubWalletController after ClubAdminController is ready.
    //    It will load its data once ClubAdminController has the club available.
    if (!Get.isRegistered<ClubWalletController>()) {
      Get.put(ClubWalletController());
    }

    // 3. Build the screen list only after controllers are registered.
    _screens = [
      const ClubCourtsScreen(),
      const ClubAgendaScreen(),
      const ClubWalletScreen(),
      const ClubProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF6B4EFF).withOpacity(0.1),
          height: 65,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: Color(0xFF6B4EFF)),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month, color: Color(0xFF6B4EFF)),
              label: 'Agenda',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon:
                  Icon(Icons.account_balance_wallet, color: Color(0xFF6B4EFF)),
              label: 'Billetera',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Color(0xFF6B4EFF)),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
