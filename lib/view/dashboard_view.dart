import 'package:flutter/material.dart';
import 'package:smarthajiri/core/config.dart';
import 'package:smarthajiri/view/attendance_view.dart';
import 'package:smarthajiri/view/home_view.dart';
import 'package:smarthajiri/view/settings_page.dart';

class DashBoardView extends StatefulWidget {
  const DashBoardView({super.key});

  @override
  State<DashBoardView> createState() => _DashBoardViewState();
}

class _DashBoardViewState extends State<DashBoardView> {
  int bottomNavIndex = 0;
  final GlobalKey<HomePageViewState> homePageKey =
      GlobalKey<HomePageViewState>();

  // late List<Widget> lstBottomScreen;

  @override
  void initState() {
    super.initState();

    // lstBottomScreen = [
    //   HomePageView(
    //     key: homePageKey,
    //     tempUrl: "${Config.getHomeUrl()}/dashboard",
    //     goingTO: Config.getFirstLoad() ? '' : 'home',
    //   ),
    //   const WebAttendanceView(),
    //   const SettingsPage(),
    // ];
  }

  void onTabTapped(int index) {
    if (index == 0 && !Config.getFirstLoad()) {
      homePageKey.currentState?.injectHomeButtonScript();

      setState(() {
        bottomNavIndex = 0;
      });

      return;
    }

    if (index == 3) {
      setState(() {
        bottomNavIndex = index;
      });

      homePageKey.currentState?.injectProfileButtonScript();

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
      body: IndexedStack(
        index: bottomNavIndex == 3 ? 0 : bottomNavIndex,
        children: [
          HomePageView(
            key: homePageKey,
            tempUrl: "${Config.getHomeUrl()}/dashboard",
            goingTO: Config.getFirstLoad() ? '' : 'home',
          ),
          WebAttendanceView(
            selectedIndex: bottomNavIndex,
          ),
          const SettingsPage(),
        ],
      ),
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
        currentIndex: bottomNavIndex,
      ),
    );
  }
}
