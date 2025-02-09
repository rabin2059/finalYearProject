import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/home/presentation/home_screen.dart';
import 'package:frontend/features/setting/presentation/setting_screen.dart';

class UserNavigation extends ConsumerStatefulWidget {
  const UserNavigation({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _UserNavigationState();
}

class _UserNavigationState extends ConsumerState<UserNavigation> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController(initialPage: 1);

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController
        .jumpToPage(index); // Handle page transitions using PageController
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
        children: <Widget>[Container(), HomeScreen(), SettingScreen()],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.bus_alert, color: Colors.black),
          label: 'Alerts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home, color: Colors.red),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle, color: Colors.red),
          label: 'Profile',
        ),
      ],
    );
  }
}
