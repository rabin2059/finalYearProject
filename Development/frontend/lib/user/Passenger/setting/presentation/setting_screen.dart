import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/user/Passenger/profile/presentation/profile_screen.dart';
import 'package:frontend/user/Passenger/setting/providers/setting_state.dart';
import 'package:frontend/user/authentication/login/providers/auth_state.dart';
import 'package:go_router/go_router.dart';

import '../../../../components/AppColors.dart';
import '../../../../components/CustomButton.dart';
import '../../../../core/constants.dart';
import '../../../authentication/login/presentation/login_screen.dart';
import '../../../authentication/login/providers/auth_provider.dart';
import '../providers/setting_provider.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingScreenState();
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  @override
  void initState() {
    final userId = ref.read(authProvider).userId;
    super.initState();
    Future.microtask(() => ref.watch(settingProvider.notifier).fetchUsers(userId!));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final settingState = ref.watch(settingProvider);

    if (!authState.isLoggedIn) {
      return const LoginScreen();
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(settingState),
            _buildMenuOptions(),
          ],
        ),
      ),
    );
  }
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
                CircleAvatar(
                  radius: 53.h, // Adjust the radius as needed
                  backgroundColor:
                      Colors.grey[200], // Fallback background color
                  child: settingState.users.isNotEmpty &&
                          settingState.users[0].images != null
                      ? ClipOval(
                          child: Image.network(
                            imageUrl + settingState.users[0].images!,
                            fit: BoxFit
                                .cover, // Ensures the image fills the circular area
                            width: 106.h, // Match the CircleAvatar diameter
                            height: 106.h,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                "assets/profile.png",
                                fit: BoxFit.cover,
                                width: 106.h,
                                height: 106.h,
                              );
                            },
                          ),
                        )
                      : ClipOval(
                          child: Image.asset(
                            "assets/profile.png", // Default profile image
                            fit: BoxFit.cover,
                            width: 106.h,
                            height: 106.h,
                          ),
                        ),
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
                    context.push('/profile');
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
                _menuButton(CupertinoIcons.bus, 'Be a Driver', '/roleChange'),
                SizedBox(height: 16.h),
                _menuButton(CupertinoIcons.person_3, 'About Us', '/about'),
                SizedBox(height: 16.h),
                _menuButton(CupertinoIcons.exclamationmark_circle, 'Help', '/help'),
                SizedBox(height: 16.h),
                _menuButton(Icons.settings, 'Settings', '/settings'),
                SizedBox(height: 16.h),
                _menuButton(Icons.key, 'Change Password', '/change_password'),
                SizedBox(height: 16.h),
                _menuButton(Icons.logout, 'Log Out', '/login'),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// **Reusable menu button**
  Widget _menuButton(IconData icon, String title, String action) {
    return GestureDetector(
      onTap: () {
        if (action == '/login') {
          ref.read(authProvider.notifier).logout();
          SettingState(users: []);
          AuthState(userId: null, currentRole: null, isLoggedIn: false);
          context.go(action);
        } else {
          context.pushNamed(action);
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
