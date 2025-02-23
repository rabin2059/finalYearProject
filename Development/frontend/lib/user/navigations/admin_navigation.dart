import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/user/Admin/admin%20home/presentation/admin_home_screen.dart';
import 'package:frontend/user/authentication/login/providers/auth_provider.dart';
import '../../components/AppColors.dart';
import 'package:go_router/go_router.dart';

class AdminNavigation extends ConsumerWidget {
  const AdminNavigation({super.key});

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
              context, Icons.people, 'Manage Users', '/manageUsers'),
          _buildDrawerItem(context, Icons.report, 'View Reports', '/reports'),
          _buildDrawerItem(context, Icons.settings, 'Settings', '/settings'),
          _buildDrawerItem(context, Icons.logout, 'Logout', '/login', ref),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title,
      String action, [WidgetRef? ref]) {
    return GestureDetector(
      onTap: () {
        if (action == '/login' && ref != null) {
          ref.read(authProvider.notifier).logout();
          context.go(action); // Navigate to login after logout
        } else {
          context.push(action); // Navigate to the respective screen
        }
      },
      child: Padding(
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
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
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
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      drawer: _buildAdminDrawer(context, ref),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.primary,
      ),
      body: const AdminHomeScreen(),
    );
  }
}