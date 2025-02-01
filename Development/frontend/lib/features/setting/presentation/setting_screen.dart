import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../components/AppColors.dart';
import '../../../components/CustomButton.dart';
import '../../authentication/presentation/login_screen.dart';
import '../../authentication/providers/auth_provider.dart';
import '../providers/setting_provider.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingScreenState();
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final settingState = ref.watch(settingProvider);

    if (!authState.isLoggedIn) {
      return const LoginScreen();
    }

    return Scaffold(
      body: Column(
        children: [
          _buildProfileHeader(settingState),
          _buildMenuOptions(),
        ],
      ),
    );
  }

  /// **Fetch user data**
  Future<void> _fetchUserData() async {
    try {
      final settingNotifier = ref.read(settingProvider.notifier);
      final authState = ref.read(authProvider);
      final userId = authState.userId;

      debugPrint('Fetching user data for userId: $userId'); // Debug print

      if (userId != null) {
        await settingNotifier.fetchUsers(userId);
      } else {
        debugPrint('User ID is null. Cannot fetch user data.');
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  /// **Builds the profile header**
  Widget _buildProfileHeader(settingState) {
    final hasUser = settingState.users.isNotEmpty;
    final user = hasUser ? settingState.users[0] : null;

    return Container(
      height: 229.h,
      decoration: const BoxDecoration(color: AppColors.primary),
      child: Padding(
        padding: EdgeInsets.all(16.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              children: [
                Container(
                  height: 106.h,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Image.asset('assets/profile.png'),
                ),
                SizedBox(width: 20.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasUser ? user!.username : 'Guest',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      hasUser && user.phone != null ? user.phone! : 'No Phone',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                        ),
                        Text(
                          hasUser && user.address != null
                              ? user.address!
                              : 'No Address',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomButton(
                  text: 'Edit Profile',
                  onPressed: () {
                    // Add your edit profile logic here
                  },
                  width: 110.w,
                  height: 30.h,
                  fontSize: 12.sp,
                  color: AppColors.primary,
                  borderColor: Colors.white,
                  boxShadow: const [],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// **Builds the settings menu**
  Widget _buildMenuOptions() {
    return Padding(
      padding: EdgeInsets.all(16.h),
      child: Column(
        children: [
          CustomButton(
            text: 'Passenger',
            onPressed: () {},
            color: const Color(0xfff0f0f0f0),
            textColor: Colors.black,
            boxShadow: const [],
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Column(
              children: [
                SizedBox(height: 16.h),
                _menuButton(CupertinoIcons.bus, 'Be a Driver'),
                SizedBox(height: 16.h),
                _menuButton(CupertinoIcons.person_3, 'About Us'),
                SizedBox(height: 16.h),
                _menuButton(CupertinoIcons.exclamationmark_circle, 'Help'),
                SizedBox(height: 16.h),
                _menuButton(Icons.settings, 'Settings'),
                SizedBox(height: 16.h),
                _menuButton(Icons.key, 'Change Password'),
                SizedBox(height: 16.h),
                _menuButton(Icons.logout, 'Log Out', isLogout: true),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// **Reusable menu button**
  Widget _menuButton(IconData icon, String title, {bool isLogout = false}) {
    return GestureDetector(
      onTap: () {
        if (isLogout) {
          ref.read(authProvider.notifier).logout();
        }
      },
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
                  padding: EdgeInsets.all(3.h),
                  child: Icon(icon),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                title,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Icon(CupertinoIcons.forward),
        ],
      ),
    );
  }
}
