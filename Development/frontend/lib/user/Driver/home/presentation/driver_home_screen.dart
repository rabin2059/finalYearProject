import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/core/constants.dart';
import 'package:frontend/user/Driver/driver%20map/driver_map_screen.dart';
import 'package:frontend/user/authentication/login/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import '../../../../components/AppColors.dart';
import '../../../../components/CustomButton.dart';
import '../../../../data/services/map_service.dart';
import '../../../Passenger/setting/providers/setting_provider.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  String? startPoint;
  String? endPoint;
  int? vehicleId;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchRouteDetails();
  }

  Future<void> _fetchUserData() async {
    try {
      final settingNotifier = ref.read(settingProvider.notifier);
      final authState = ref.read(authProvider);
      final userId = authState.userId;

      if (userId != null) {
        await settingNotifier.fetchUsers(userId);
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> _fetchRouteDetails() async {
    try {
      final vehicle = ref.read(settingProvider).users[0];
      vehicleId = vehicle.vehicleId;

      final url = Uri.parse("$apiBaseUrl/getMyRoute?id=$vehicleId");
      final response = await http.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        startPoint = jsonResponse['route']['startPoint'];
        endPoint = jsonResponse['route']['endPoint'];
      }
    } catch (e) {
      debugPrint('Error fetching route details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingState = ref.watch(settingProvider);

    final hasUser = settingState.users.isNotEmpty;
    final user = hasUser ? settingState.users[0] : null;
    final userName = hasUser ? user!.username : "Guest";
    final userEmail = hasUser ? user!.email ?? "No Email" : "guest@example.com";
    final userImage =
        hasUser && user!.images != null ? user.images! : "assets/profile.png";

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(userName!, userEmail, userImage),
          _buildUserOptions(context),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (startPoint != null && endPoint != null && vehicleId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DriverMapScreen(
                  vehicleId: vehicleId!,
                  startLocation: startPoint!,
                  endLocation: endPoint!,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to load route")),
            );
          }
        },
        label: const Text("Open Map"),
        icon: const Icon(Icons.map),
        backgroundColor: AppColors.primary,
      ),
    );
  }

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
                    style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserOptions(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          CustomButton(
            text: "Request a Ride",
            width: double.infinity,
            onPressed: () {},
            color: AppColors.secondary,
          ),
          SizedBox(height: 10.h),
          CustomButton(
            text: "View Ride History",
            width: double.infinity,
            onPressed: () {},
            color: AppColors.secondary,
          ),
          SizedBox(height: 10.h),
          CustomButton(
            text: "Edit Profile",
            width: double.infinity,
            onPressed: () {},
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}
