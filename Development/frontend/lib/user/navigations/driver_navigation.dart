import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Driver/booking lists/presentation/book_vehicle_list_screen.dart';
import '../Driver/home/presentation/driver_home_screen.dart';
import '../Driver/setting/presentation/driver_setting_screen.dart';

final driverTabIndexProvider = StateProvider<int>((ref) => 1); // Default to Home


class DriverNavigation extends ConsumerStatefulWidget {
  const DriverNavigation({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DriverNavigationState();
}

class _DriverNavigationState extends ConsumerState<DriverNavigation> {
  void _onItemTapped(int index) {
    ref.read(driverTabIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(driverTabIndexProvider);
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [
          BookVehicleListScreen(),
          DriverHomeScreen(),
          DriverSettingScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(selectedIndex),
    );
  }

  /// **Updated Bottom Navigation Bar with Active Icon Highlighting**
  Widget _buildBottomNavigationBar(int selectedIndex) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: _onItemTapped,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.bus_alert),
          label: 'Alerts',
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
