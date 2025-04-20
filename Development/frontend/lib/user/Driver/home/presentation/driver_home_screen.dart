import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/core/constants.dart';
import 'package:frontend/user/Driver/driver map/driver_map_screen.dart';
import 'package:frontend/user/Passenger/bus details/providers/bus_details_provider.dart';
import 'package:frontend/user/authentication/login/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import '../../../../components/AppColors.dart';
import '../../../../components/CustomButton.dart';
import '../../../../data/services/map_service.dart';
import '../../../Passenger/setting/providers/setting_provider.dart';
import '../../vehicle details/provider/vehicle_details_provider.dart';
import '../provider/driver_provider.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() =>
      _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  String? startPoint;
  String? endPoint;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authProvider).userId;
    if (userId != null) {
      // Load profile/user data
      ref.read(settingProvider.notifier).fetchUsers(userId).then((_) {
        final settingState = ref.read(settingProvider);
        if (settingState.users.isNotEmpty) {
          final vehicleId = settingState.users[0].vehicleId;
          ref.read(vehicleProvider.notifier).loadVehicle(vehicleId);
        }
      });
      // Load driver stats
      ref.read(driverProvider.notifier).fetchDriverData(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingState = ref.watch(settingProvider);
    final hasUser = settingState.users.isNotEmpty;
    final user = hasUser ? settingState.users[0] : null;
    final vehicleId = hasUser ? user!.vehicleId ?? -1 : -1;
    final userName = hasUser ? user!.username : "Guest";
    final userEmail = hasUser ? user!.email ?? "No Email" : "guest@example.com";
    final userImage =
        hasUser && user!.images != null ? user.images! : "assets/profile.png";

    final driverState = ref.watch(driverProvider);
    final vehicleState = ref.watch(vehicleProvider);


    final stats = driverState.driverData?.driverStats;
    final hasStats = stats != null;
    final totalTripsValue    = hasStats ? stats!.totalTrips.toString()   : '0';
    final totalEarningsValue = hasStats ? 'Rs.${stats!.totalEarnings}'    : 'Rs.0';
    final ratingValue        = hasStats ? stats!.rating.toString()       : '0.0';
    final statusValue        = hasStats ? "Online"                 : 'Offline';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: () async {
          final userId = ref.read(authProvider).userId;
          if (userId != null) {
            await ref.read(settingProvider.notifier).fetchUsers(userId);
            await ref.read(driverProvider.notifier).fetchDriverData(userId);
          }
        },
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(userName!, userEmail, userImage, statusValue!),
              _buildStatusCard(vehicleId),
              _buildStatsRow(totalTripsValue, totalEarningsValue, ratingValue),
              _buildActionCards(vehicleId),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildHeader(
      String name, String email, String imageUrl, String status) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            const Color(0xFF2980b9),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.r),
          bottomRight: Radius.circular(30.r),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.w),
                  ),
                  child: CircleAvatar(
                    radius: 40.r,
                    backgroundImage: AssetImage(imageUrl),
                    onBackgroundImageError: (_, __) =>
                        const Icon(Icons.person, size: 40),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, $name!",
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'Online'
                              ? Colors.green
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              status,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(dynamic vehicleId) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.directions_bus_outlined,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Vehicle",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        "Bus ${vehicleId ?? 'Loading...'}",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black54,
                        ),
                      ),
                      
                    ],
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      "Active",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("From",
                              style: TextStyle(
                                  fontSize: 12.sp, color: Colors.black54)),
                          SizedBox(height: 4.h),
                          Text(startPoint ?? "Kathmandu",
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("To",
                              style: TextStyle(
                                  fontSize: 12.sp, color: Colors.black54)),
                          SizedBox(height: 4.h),
                          Text(endPoint ?? "Pokhara",
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
      String totalTripsValue, String totalEarningsValue, String ratingValue) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          _buildStatCard(
            title: "Total Trips",
            value: totalTripsValue,
            icon: Icons.route,
            iconColor: Colors.blue,
          ),
          SizedBox(width: 12.w),
          _buildStatCard(
            title: "Earnings",
            value: totalEarningsValue,
            icon: Icons.account_balance_wallet,
            iconColor: Colors.green,
          ),
          SizedBox(width: 12.w),
          _buildStatCard(
            title: "Rating",
            value: ratingValue,
            icon: Icons.star,
            iconColor: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20.sp,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCards(int vehicleId) {
    final actions = [
      {
        'title': 'Start Trip',
        'icon': Icons.play_circle_outline,
        'color': Colors.green,
        'action': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DriverMapScreen(
                vehicleId: vehicleId,
              ),
            ),
          );
        },
      },
      {
        'title': 'Trip History',
        'icon': Icons.history,
        'color': Colors.blue,
        'action': () {
          // TODO: implement trip history page
        },
      },
      {
        'title': 'Edit Profile',
        'icon': Icons.person_outline,
        'color': Colors.purple,
        'action': () {
          // TODO: implement edit profile
        },
      },
    ];

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Actions",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return GestureDetector(
                onTap: action['action'] as void Function(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: (action['color'] as Color).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          action['icon'] as IconData,
                          color: action['color'] as Color,
                          size: 28.sp,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        action['title'] as String,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}