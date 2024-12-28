import 'package:flutter/material.dart';
import 'package:merobus/Screens/Main%20Screens/admin_screen.dart';
import '../Components/AppColors.dart';
import '../Screens/Main Screens/setting_screen.dart';
import '../Screens/Main Screens/home_screen.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key, required this.dept});
  final int dept; // dept represents role: 0 -> Admin, 1 -> Passenger, 2 -> Driver

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _selectedIndex = 0;
  PageController _pageController = PageController(initialPage: 1);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.dept; // Set the initial index based on the role
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index); // Handle page transitions using PageController
  }

  Widget _buildBottomNavigationBar() {
    if (widget.dept == 0) {
      // Admin: No BottomNavigationBar for Admin
      return Container();
    } else {
      // Passenger and Driver: Use BottomNavigationBar
      return BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bus_alert, color: AppColors.primary),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: AppColors.primary),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      );
    }
  }

  Widget _buildAdminDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.primary),
            child: Text(
              'Admin Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manage Users'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('View Reports'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingScreen(dept: widget.dept),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              // Add your logout logic here
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Admin Navigation
    if (widget.dept == 0) {
      return Scaffold(
        drawer: _buildAdminDrawer(),
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: AppColors.primary,
        ),
        body: const AdminScreen(),
      );
    } else {
      // Passenger/Driver Navigation
      return Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: <Widget>[
            const Center(child: Text('Alerts Screen')),
            HomeScreen(dept: widget.dept), // Shared HomeScreen for Passenger/Driver
            SettingScreen(dept: widget.dept),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      );
    }
  }
}