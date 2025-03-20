import 'package:flutter/material.dart';
import 'package:smarthajiri/view/attendance_view.dart';
import 'package:smarthajiri/view/home_view.dart';
import 'package:smarthajiri/view/settings_page.dart';

class DashBoardView extends StatefulWidget {
  const DashBoardView({super.key});

  @override
  State<DashBoardView> createState() => DashBoardViewState();
}

class DashBoardViewState extends State<DashBoardView> {
  int bottomNavIndex = 0;
  final GlobalKey<HomePageViewState> homePageKey =
      GlobalKey<HomePageViewState>();

  late List<Widget> lstBottomScreen;
  int profileIndex = 10;

  @override
  void initState() {
    super.initState();

    lstBottomScreen = [
      HomePageView(
        key: homePageKey,
      ),
      const WebAttendanceView(),
      // const NotificationsPage(),
      const SettingsPage(),
    ];
  }

  void goToHome() {
    homePageKey.currentState?.injectTokenAndReload();
  }

  void onTabTapped(int index) {
    profileIndex = 10;

    if (index == 3) {
      homePageKey.currentState?.injectProfileButtonScript();

      setState(() {
        bottomNavIndex = 0;
        profileIndex = index;
      });
      return;
    }

    if (index == 0) {
      homePageKey.currentState?.injectHomeButtonScript();

      setState(() {
        bottomNavIndex = 0;
      });
      return;
    }

    setState(() {
      bottomNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: lstBottomScreen[bottomNavIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner_outlined),
            label: 'Attendance',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.notifications),
          //   label: 'Notifications',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: onTabTapped,
        selectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: profileIndex == 10 ? bottomNavIndex : 3,
      ),
    );
  }
}
