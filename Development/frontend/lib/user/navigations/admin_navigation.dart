import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/user/Admin/admin%20home/presentation/admin_home_screen.dart';
import 'package:frontend/user/Admin/admin%20request/presentation/admin_request_screen.dart';
import 'package:frontend/user/authentication/login/providers/auth_provider.dart';
import '../../components/AppColors.dart';
import 'package:go_router/go_router.dart';

class AdminNavigation extends StatefulWidget {
  const AdminNavigation({super.key});

  @override
  State<AdminNavigation> createState() => _AdminNavigationState();
}

class _AdminNavigationState extends State<AdminNavigation> {
  String _selectedRoute = '/dashboard';

  Widget _buildBody() {
    switch (_selectedRoute) {
      case '/dashboard':
        return const AdminHomeScreen();
      case '/requests':
        return const AdminRequestScreen();
      case '/reports':
        return Text('View Reports');
      case '/settings':
        return Text('Settings');
      default:
        return const AdminHomeScreen();
    }
  }

  Widget _buildAdminDrawer(BuildContext context, WidgetRef ref) {
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
          _buildDrawerItem(context, Icons.dashboard, 'Dashboard', '/dashboard'),
          _buildDrawerItem(
              context, Icons.people, 'Manage Requests', '/requests'),
          _buildDrawerItem(context, Icons.report, 'View Reports', '/reports'),
          _buildDrawerItem(context, Icons.settings, 'Settings', '/settings'),
          _buildDrawerItem(context, Icons.logout, 'Logout', '/login', ref),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, String action,
      [WidgetRef? ref]) {
    final bool isSelected = _selectedRoute == action;

    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close the drawer
        if (action == '/login' && ref != null) {
          ref.read(authProvider.notifier).logout();
          context.go(action);
        } else {
          setState(() {
            _selectedRoute = action;
          });
        }
      },
      child: Container(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  height: 36.h,
                  width: 36.h,
                  decoration: BoxDecoration(
                    color: AppColors.iconColor,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(6.h),
                    child: Icon(icon, color: Colors.white),
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.primary : Colors.black,
                  ),
                ),
              ],
            ),
            const Icon(CupertinoIcons.forward, color: Colors.black),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Scaffold(
          drawer: _buildAdminDrawer(context, ref),
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            backgroundColor: AppColors.primary,
          ),
          body: _buildBody(),
        );
      },
    );
  }
}
