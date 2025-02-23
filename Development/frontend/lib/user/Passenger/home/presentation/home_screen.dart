import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/components/AppColors.dart';
import 'package:frontend/components/CustomButton.dart';
import 'package:frontend/user/Passenger/map/presentation/map_screen.dart';
import 'package:frontend/user/authentication/login/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

import '../../setting/providers/setting_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data on init
  }

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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final settingState = ref.watch(settingProvider);

    // Fetch the first user data (if available)
    final hasUser = settingState.users.isNotEmpty;
    final user = hasUser ? settingState.users[0] : null;
    final userName = hasUser ? user!.username : "Guest";
    final userEmail = hasUser ? user!.email ?? "No Email" : "guest@example.com";
    final userImage = hasUser && user!.images != null
        ? user.images!
        : "assets/profile.png"; // Default image if none available

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(userName!, userEmail, userImage), // User Profile Section
          _buildUserOptions(context), // Quick Actions Section
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapScreens()),
          );
        },
        label: const Text("Open Map"),
        icon: const Icon(Icons.map),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  /// **🔹 Header: Shows User Info (Profile, Name, Email)**
  Widget _buildHeader(String name, String email, String imageUrl) {
    return Container(
      height: 200.h,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40.r,
                backgroundImage: AssetImage(imageUrl),
                onBackgroundImageError: (_, __) =>
                    const Icon(Icons.person, size: 40),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, $name!",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    email,
                    style: TextStyle(fontSize: 15.sp, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// **🔹 Quick Action Buttons**
  Widget _buildUserOptions(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          CustomButton(
            text: "Request a Ride",
            width: double.infinity,
            onPressed: () {
              // Implement ride request feature
            },
            color: AppColors.secondary,
          ),
          SizedBox(height: 10.h),
          CustomButton(
            text: "View Ride History",
            width: double.infinity,
            onPressed: () {
              // Implement ride history feature
            },
            color: AppColors.secondary,
          ),
          SizedBox(height: 10.h),
          CustomButton(
            text: "Edit Profile",
            width: double.infinity,
            onPressed: () {
              // Implement profile editing
            },
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}
