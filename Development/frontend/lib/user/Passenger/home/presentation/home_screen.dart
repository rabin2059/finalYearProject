import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/cupertino.dart';
import 'package:merobus/user/Passenger/setting/providers/setting_state.dart';
import '../../../../components/AppColors.dart';
import '../../../../core/constants.dart';
import '../../../authentication/login/providers/auth_provider.dart';
import '../../user map/presentation/map_screen.dart';
import '../provider/passenger_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../setting/providers/setting_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  dynamic _upcomingTrip;

  @override
  void initState() {
    super.initState();
    _fetchUserData().then((_) {
      _saveFcmTokenToServer();
      final authState = ref.read(authProvider);
      final userId = authState.userId;
      if (userId != null) {
        ref.read(passengerProvider.notifier).fetchHomeData(userId);
        Future.microtask(() =>_fetchUpcomingTrip(userId));
      }
    });
  }

  Future<void> _fetchUpcomingTrip(int userId) async {
    try {
      final response =
          await http.get(Uri.parse('$apiBaseUrl/upcoming-trip?userId=$userId'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['trips'] != null && json['trips'].isNotEmpty) {
          setState(() {
            _upcomingTrip = json['trips'];
          });
        }
      } else {
        debugPrint('Failed to fetch upcoming trip: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching upcoming trip: $e');
    }
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

  Future<void> _saveFcmTokenToServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('fcmToken');
      final authState = ref.read(authProvider);
      final userId = authState.userId;

      if (token != null && userId != null) {
        final response = await http.put(
          Uri.parse('$apiBaseUrl/saveToken'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId.toString(),
            'fcmToken': token,
          }),
        );
        if (response.statusCode == 200) {
          debugPrint('FCM token saved successfully');
        } else {
          debugPrint('Failed to save FCM token: ${response.body}');
        }
      } else {
        debugPrint('No token or userId to save');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userId = authState.userId;
    
    final passengerState = ref.watch(passengerProvider);
    final homeData = passengerState.homeData;
    final hasData = homeData != null;
    final userName = hasData ? homeData.user!.username : "Guest";
    final userEmail =
        hasData ? homeData.user!.email ?? "No Email" : "guest@example.com";
    final userImage = hasData && homeData.user!.images != null
        ? homeData.user!.images!
        : "assets/profile.png";
    final recentTripsValue = hasData ? homeData.recentTrips.toString() : "0";
    final totalExpendValue = hasData ? "₹${homeData.totalExpend}" : "₹0";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(
              userName!,
              userEmail,
              userImage,
              recentTripsValue,
              totalExpendValue,
              ref.watch(settingProvider),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Upcoming Trip",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Column(
                    children: (_upcomingTrip != null &&
                            (_upcomingTrip as List).isNotEmpty)
                        ? (_upcomingTrip as List).map<Widget>((trip) {
                            return Container(
                              margin: EdgeInsets.only(bottom: 12.h),
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: AppColors.buttonText,
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.textPrimary.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.directions_bus,
                                      color: AppColors.primary),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${(trip['pickUpPoint'] as String).split(',').first} → ${(trip['dropOffPoint'] as String).split(',').first}",
                                          style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary),
                                        ),
                                        SizedBox(height: 4.h),
                                        Text(
                                          "Departure: ${DateTime.parse(trip['bookingDate']).toLocal().toString().split(' ').first}",
                                          style: TextStyle(
                                              fontSize: 14.sp,
                                              color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList()
                        : [],
                  ),
                ],
              ),
            ),
            SizedBox(height: 80.h),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapScreens()),
            );
          },
          label: Text(
            "Open Live Map",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
              color: AppColors.buttonText,
            ),
          ),
          icon: Icon(Icons.map_outlined, color: AppColors.buttonText),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }

  /// Premium header with gradient and user info
  Widget _buildHeader(
      String name,
      String email,
      String image,
      String recentTripsValue,
      String totalExpendValue,
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
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // User info section
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.buttonText,
                      width: 2.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
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
                              "assets/profile.png",
                              fit: BoxFit.cover,
                              width: 106.h,
                              height: 106.h,
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
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.buttonText,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: AppColors.buttonText.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.buttonText.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: IconButton(
                    onPressed: () {
                      context.push('/notifications');
                    },
                    icon: Icon(
                      Icons.notifications_none_outlined,
                      color: AppColors.buttonText,
                      size: 20.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quick status cards
          Padding(
            padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    icon: Icons.history,
                    title: "Recent Trips",
                    value: recentTripsValue,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildStatusCard(
                    icon: Icons.wallet,
                    title: "Total Expenses",
                    value: totalExpendValue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build status card
  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.buttonText,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.buttonText.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: AppColors.buttonText,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.buttonText.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.buttonText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
