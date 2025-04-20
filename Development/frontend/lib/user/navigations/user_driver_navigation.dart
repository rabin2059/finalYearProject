import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Driver/setting/presentation/driver_setting_screen.dart';
import '../Passenger/bus list/presentation/bus_screen.dart';
import '../Passenger/home/presentation/home_screen.dart';

class UserDriverNavigation extends ConsumerStatefulWidget {
  const UserDriverNavigation({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _UserDriverNavigationState();
}

class _UserDriverNavigationState extends ConsumerState<UserDriverNavigation> {
  int _selectedIndex = 1; // Default to Home
  final PageController _pageController = PageController(initialPage: 1);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          BusScreen(),
          HomeScreen(),
          DriverSettingScreen()
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// **Updated Bottom Navigation Bar with Active Icon Highlighting**
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: Colors.blue, // ✅ Color for the selected icon
      unselectedItemColor: Colors.grey, // ✅ Default color for inactive icons
      items: [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.bus_alert,
            color: _selectedIndex == 0
                ? Colors.blue
                : Colors.grey, // ✅ Dynamic Color Change
          ),
          label: 'Alerts',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.home,
            color: _selectedIndex == 1
                ? Colors.blue
                : Colors.grey, // ✅ Dynamic Color Change
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.account_circle,
            color: _selectedIndex == 2
                ? Colors.blue
                : Colors.grey, // ✅ Dynamic Color Change
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}
