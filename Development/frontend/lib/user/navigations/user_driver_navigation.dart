import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Driver/setting/presentation/driver_setting_screen.dart';
import '../Passenger/bus list/presentation/bus_screen.dart';
import '../Passenger/home/presentation/home_screen.dart';

final userDriverTabIndexProvider = StateProvider<int>((ref) => 1);

class UserDriverNavigation extends ConsumerStatefulWidget {
  const UserDriverNavigation({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _UserDriverNavigationState();
}

class _UserDriverNavigationState extends ConsumerState<UserDriverNavigation> {
  void _onItemTapped(int index) {
    ref.read(userDriverTabIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(userDriverTabIndexProvider);
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [
          BusScreen(),
          HomeScreen(),
          DriverSettingScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(selectedIndex),
    );
  }

  Widget _buildBottomNavigationBar(int selectedIndex) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: _onItemTapped,
      selectedItemColor: Colors.blue, 
      unselectedItemColor: Colors.grey, 
      items: [
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.bus),
          label: 'Buses',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Profile',
        ),
      ],
    );
  }
}
