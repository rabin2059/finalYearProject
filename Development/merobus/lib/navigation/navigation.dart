import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:merobus/Components/CustomButton.dart';
import 'package:merobus/Screens/Authentication/signin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Components/AppColors.dart';
import '../Screens/maps/map.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key, required this.dept});
  final int dept;

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  Future<void> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print(token);
  }

  List<Widget> _buildPassengerScreens(BuildContext context) {
    return [
      Center(
          child: CustomButton(
              text: "Map",
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => MapScreen())))),
      const Center(child: Text('Passenger Option 2')),
      const Center(child: Text('Passenger Option 3')),
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomButton(text: "Be Driver", onPressed: () {}),
            SizedBox(height: 10.h),
            CustomButton(
              text: "Sign out",
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignIn()),
                );
              },
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    int dept = widget.dept;

    switch (dept) {
      case 0: // Admin
        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            backgroundColor: AppColors.primary,
          ),
          drawer: Drawer(
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
                    setState(() {
                      _selectedIndex = 0;
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignIn()));
                  },
                ),
              ],
            ),
          ),
          body: [
            const Center(child: Text('Admin Option 1')),
            const Center(child: Text('Admin Option 2')),
          ][_selectedIndex], // Admin screens
        );

      case 1: // Passenger
        return Scaffold(
          body: _buildPassengerScreens(context)[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home, color: AppColors.primary),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search, color: AppColors.primary),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications, color: AppColors.primary),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle, color: AppColors.primary),
                label: '',
              ),
            ],
          ),
        );

      case 2: // Driver
      default:
        return Scaffold(
          body: [
            const Center(child: Text('Driver Option 1')),
            const Center(child: Text('Driver Option 2')),
            const Center(child: Text('Driver Option 3')),
            const Center(child: Text('Driver Option 4')),
          ][_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home, color: AppColors.primary),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search, color: AppColors.primary),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications, color: AppColors.primary),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle, color: AppColors.primary),
                label: '',
              ),
            ],
          ),
        );
    }
  }
}
