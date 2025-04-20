import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Passenger/bus list/presentation/bus_screen.dart';
import '../Passenger/home/presentation/home_screen.dart';
import '../Passenger/setting/presentation/setting_screen.dart';

final userTabIndexProvider = StateProvider<int>((ref) => 1);

class UserNavigation extends ConsumerStatefulWidget {
  const UserNavigation({super.key});

  @override
  ConsumerState<UserNavigation> createState() => _UserNavigationState();
}

class _UserNavigationState extends ConsumerState<UserNavigation> {
  void _onItemTapped(int index) {
    ref.read(userTabIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(userTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: const [BusScreen(), HomeScreen(), SettingScreen()],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(selectedIndex),
    );
  }

  Widget _buildBottomNavigationBar(int selectedIndex) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: _onItemTapped,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.bus_alert),
          label: 'Alerts',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Profile',
        ),
      ],
    );
  }
}
