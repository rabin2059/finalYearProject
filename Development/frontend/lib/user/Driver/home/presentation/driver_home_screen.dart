import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import '../../../../components/AppColors.dart';
import '../../../../components/CustomButton.dart';
import '../../../../core/constants.dart';
import '../../../../data/services/map_service.dart';
import '../../../Passenger/setting/providers/setting_provider.dart';
import '../../../Passenger/setting/providers/setting_state.dart';
import '../../../authentication/login/providers/auth_provider.dart';
import '../../driver map/driver_map_screen.dart';
import '../../vehicle details/provider/vehicle_details_provider.dart';
import '../provider/driver_provider.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  String? startPoint;
  String? endPoint;
  double _driverAverageRating = 0.0;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authProvider).userId;
    if (userId != null) {
      ref.read(settingProvider.notifier).fetchUsers(userId).then((_) {
        final settingState = ref.read(settingProvider);
        if (settingState.users.isNotEmpty) {
          final vehicleId = settingState.users[0].vehicleId;
          ref.read(vehicleProvider.notifier).loadVehicle(vehicleId);
        }
      });
      ref.read(driverProvider.notifier).fetchDriverData(userId);
      fetchDriverRatings(userId);
    }
  }

  void fetchDriverRatings(int driverId) async {
    final response =
        await http.get(Uri.parse('$apiBaseUrl/getRating/$driverId'));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List ratings = json['result'];

      if (ratings.isNotEmpty) {
        double sum = ratings.fold(0.0, (acc, val) => acc + val['rating']);
        setState(() {
          _driverAverageRating =
              double.parse((sum / ratings.length).toStringAsFixed(1));
        });
      }
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

    final vehicle = vehicleState.vehicle?.route?.isNotEmpty == true
        ? vehicleState.vehicle!.route![0]
        : null;

    // Show loading indicator if user, vehicle, or driver data is not ready
    if (!hasUser || vehicle == null || vehicleState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final startPoint = vehicle.startPoint;
    final endpoint = vehicle.endPoint;
    final stats = driverState.driverData?.driverStats;
    final hasStats = stats != null;
    final totalTripsValue = hasStats ? stats.totalTrips.toString() : '0';
    final totalEarningsValue = hasStats ? 'Rs.${stats.totalEarnings}' : 'Rs.0';
    final ratingValue =
        _driverAverageRating > 0 ? _driverAverageRating.toString() : '0.0';
    final statusValue = hasStats ? "Online" : 'Offline';

    return Scaffold(
      backgroundColor: AppColors.background,
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
              _buildHeader(
                  userName!, userEmail, userImage, statusValue, settingState),
              _buildStatusCard(vehicle),
              _buildStatsRow(totalTripsValue, totalEarningsValue, ratingValue),
              // _buildActionCards(vehicleId), // Removed action cards
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DriverMapScreen(vehicleId: vehicleId),
            ),
          );
        },
        label: Text(
          "Open Map",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15.sp,
            color: AppColors.buttonText,
          ),
        ),
        icon: Icon(Icons.map_outlined, color: AppColors.buttonText),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildHeader(String name, String email, String image, String status,
      SettingState settingState) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: AppColors.primary,
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
                    border: Border.all(color: AppColors.buttonText, width: 2.w),
                  ),
                  child: CircleAvatar(
                    radius: 53.h,
                    backgroundColor: Colors.grey[200],
                    child: settingState.users.isNotEmpty &&
                            settingState.users[0].images != null
                        ? ClipOval(
                            child: Image.network(
                              imageUrl + image,
                              fit: BoxFit.cover,
                              width: 106.h,
                              height: 106.h,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Text(
                                    "assets/profile.png",
                                    style: TextStyle(
                                        fontSize: 10.sp,
                                        color: AppColors.textPrimary),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Text(
                              "assets/profile.png",
                              style: TextStyle(
                                  fontSize: 10.sp,
                                  color: AppColors.textPrimary),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
                          color: AppColors.buttonText,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.buttonText.withOpacity(0.8),
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
                              ? AppColors.messageSent
                              : AppColors.textSecondary,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: AppColors.buttonText,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              status,
                              style: TextStyle(
                                color: AppColors.buttonText,
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

  Widget _buildStatusCard(vehicle) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.buttonText,
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        vehicle != null && vehicle.id != null
                            ? "Bus ${vehicle.id}"
                            : "No Vehicle Available",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
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
                      color: AppColors.messageSent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.messageSent.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      "Active",
                      style: TextStyle(
                        color: AppColors.messageSent,
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
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("From",
                              style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.textSecondary)),
                          SizedBox(height: 4.h),
                          Text(
                              vehicle?.startPoint?.split(',').first ??
                                  "No Start Point",
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("To",
                              style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.textSecondary)),
                          SizedBox(height: 4.h),
                          Text(
                              vehicle?.endPoint?.split(',').first ??
                                  "No End Point",
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
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
            iconColor: AppColors.buttonColor,
          ),
          SizedBox(width: 12.w),
          _buildStatCard(
            title: "Earnings",
            value: totalEarningsValue,
            icon: Icons.account_balance_wallet,
            iconColor: AppColors.messageSent,
          ),
          SizedBox(width: 12.w),
          _buildStatCard(
            title: "Rating",
            value: ratingValue,
            icon: Icons.star,
            iconColor: AppColors.accent,
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
          color: AppColors.buttonText,
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
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
