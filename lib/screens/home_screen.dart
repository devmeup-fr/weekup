import 'package:flutter/material.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:motion_tab_bar/MotionTabBarController.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late MotionTabBarController _motionTabController;
  int _currentIndex = 2;
  final int _initTabBarIndex = 2;

  List<TabItem> tabs = [
    TabItem(label: "Matches", icon: Icons.gamepad, badge: Container()),
    TabItem(
      label: "Tournois",
      icon: Icons.tab,
      badge: Container(),
    ),
    TabItem(
      label: "Joueurs",
      icon: Icons.people,
      badge: Container(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _motionTabController = MotionTabBarController(
      initialIndex: _initTabBarIndex,
      length: tabs.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _motionTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Les Dracailles FaB")),
      body: Center(
        child: _currentIndex == 0
            ? const Text("Écran des Matches")
            : _currentIndex == 1
                ? const Text("Écran des Tournois")
                : const Text("Écran des Joueurs"),
      ),
      bottomNavigationBar: MotionTabBar(
        controller: _motionTabController,
        initialSelectedTab: tabs[_currentIndex].label,
        labels: tabs.map((e) => e.label).toList(),
        icons: tabs.map((e) => e.icon).toList(),
        tabSize: 50,
        tabBarHeight: 50,
        textStyle: TextStyle(
          fontSize: 0,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
        tabIconColor: Theme.of(context).colorScheme.primary,
        tabIconSize: 28.0,
        tabIconSelectedSize: 26.0,
        tabSelectedColor: Theme.of(context).colorScheme.primary,
        tabIconSelectedColor: Colors.white,
        tabBarColor: Colors.white,
        onTabItemSelected: (int value) {
          setState(() {
            _currentIndex = value;
            _motionTabController.index = value;
          });
        },
        badges: tabs.map((e) {
          return e.badge;
        }).toList(),
      ),
    );
  }
}

class TabItem {
  final String label;
  final IconData icon;
  final Widget badge;

  TabItem({required this.label, required this.icon, required this.badge});
}
