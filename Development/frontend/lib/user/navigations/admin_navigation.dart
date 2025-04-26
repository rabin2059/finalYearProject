import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/AppColors.dart';
import 'package:go_router/go_router.dart';

import '../Admin/admin home/presentation/admin_home_screen.dart';
import '../Admin/admin request/presentation/admin_request_screen.dart';
import '../authentication/login/providers/auth_provider.dart';

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
        return const Center(child: Text('View Reports'));
      case '/settings':
        return const Center(child: Text('Settings'));
      default:
        return const AdminHomeScreen();
    }
  }

  Widget _buildAdminDrawer(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider);
    
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 2,
      child: Column(
        children: [
          // Drawer Header with Admin Profile
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 50.h, 20.w, 20.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(3.r),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 30.r,
                        backgroundColor: AppColors.iconColor,
                        child: Icon(
                          Icons.person,
                          size: 30.r,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 15.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: Colors.white,
                        size: 16.r,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Administrator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation Section
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  child: Text(
                    'MAIN NAVIGATION',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                _buildDrawerItem(
                  context, 
                  Icons.dashboard_outlined,
                  Icons.dashboard,
                  'Dashboard', 
                  '/dashboard',
                  subtitle: 'Overview & Statistics',
                ),
                _buildDrawerItem(
                  context, 
                  Icons.people_outline,
                  Icons.people,
                  'Manage Requests', 
                  '/requests',
                  subtitle: 'User & Driver Requests',
                ),
                _buildDrawerItem(
                  context, 
                  Icons.insert_chart_outlined,
                  Icons.insert_chart,
                  'View Reports', 
                  '/reports',
                  subtitle: 'Analytics & Data',
                ),
                
                Divider(height: 40.h, thickness: 1, indent: 20.w, endIndent: 20.w),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  child: Text(
                    'PREFERENCES',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                _buildDrawerItem(
                  context, 
                  Icons.settings_outlined,
                  Icons.settings,
                  'Settings', 
                  '/settings',
                  subtitle: 'App Configuration',
                ),
              ],
            ),
          ),
          
          // Logout Section
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
              ),
            ),
            child: _buildLogoutItem(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, 
    IconData outlinedIcon,
    IconData filledIcon,
    String title, 
    String route, 
    {String? subtitle}
  ) {
    final bool isSelected = _selectedRoute == route;

    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close the drawer
        setState(() {
          _selectedRoute = route;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        child: Row(
          children: [
            Container(
              height: 42.h,
              width: 42.h,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.iconColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Center(
                child: Icon(
                  isSelected ? filledIcon : outlinedIcon,
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: 20.r,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 4.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutItem(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      leading: Container(
        height: 42.h,
        width: 42.h,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Center(
          child: Icon(
            Icons.logout,
            color: Colors.red,
            size: 20.r,
          ),
        ),
      ),
      title: Text(
        'Logout',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: Colors.red,
        ),
      ),
      subtitle: Text(
        'Sign out of your account',
        style: TextStyle(
          fontSize: 12.sp,
          color: AppColors.textSecondary,
        ),
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close drawer
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: _buildAdminDrawer(context, ref),
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            title: Text(
              _getAppBarTitle(),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
              SizedBox(width: 8.w),
            ],
          ),
          body: _buildBody(),
        );
      },
    );
  }

  String _getAppBarTitle() {
    switch (_selectedRoute) {
      case '/dashboard':
        return 'Admin Dashboard';
      case '/requests':
        return 'Manage Requests';
      case '/reports':
        return 'View Reports';
      case '/settings':
        return 'Settings';
      default:
        return 'Admin Dashboard';
    }
  }


  int _getNavBarIndex() {
    switch (_selectedRoute) {
      case '/dashboard':
        return 0;
      case '/requests':
        return 1;
      case '/reports':
        return 2;
      case '/settings':
        return 3;
      default:
        return 0;
    }
  }
}