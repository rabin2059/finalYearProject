import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/components/AppColors.dart';
import 'package:frontend/components/CustomButton.dart';
import 'package:flutter/cupertino.dart';
import 'package:frontend/core/constants.dart';
import 'package:frontend/user/Passenger/user%20map/presentation/map_screen.dart';
import '../provider/passenger_provider.dart';
import 'package:frontend/user/authentication/login/providers/auth_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchUserData().then((_) {
      _saveFcmTokenToServer();
      final authState = ref.read(authProvider);
      final userId = authState.userId;
      if (userId != null) {
        ref.read(passengerProvider.notifier).fetchHomeData(userId);
      }
    });
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

  /// Retrieve stored FCM token and send it to backend
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
    final passengerState = ref.watch(passengerProvider);
    final homeData = passengerState.homeData;
    final hasData = homeData != null;
    final userName = hasData ? homeData!.user!.username : "Guest";
    final userEmail = hasData ? homeData.user!.email ?? "No Email" : "guest@example.com";
    final userImage = hasData && homeData.user!.images != null
        ? homeData.user!.images!
        : "assets/profile.png";
    final recentTripsValue = hasData ? homeData.recentTrips.toString() : "0";
    final totalExpendValue = hasData ? "₹${homeData.totalExpend}" : "₹0";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(userName!, userEmail, userImage, recentTripsValue, totalExpendValue), // User Profile Section
            _buildPopularDestinations(), // Popular Destinations Carousel
            _buildQuickActions(context), // Quick Actions Grid
            _buildFeaturedServices(context), // Featured Services
            SizedBox(height: 80.h), // For FloatingActionButton space
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
            ),
          ),
          icon: const Icon(Icons.map_outlined),
          backgroundColor: AppColors.primary,
        ),
      ),
    );
  }

  /// Premium header with gradient and user info
  Widget _buildHeader(String name, String email, String imageUrl, String recentTripsValue, String totalExpendValue) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color.fromARGB(255, 56, 147, 216),
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
                      color: Colors.white,
                      width: 2.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 40.r,
                    backgroundImage: AssetImage(imageUrl),
                    onBackgroundImageError: (_, __) =>
                        const Icon(Icons.person, size: 40),
                    backgroundColor: Colors.white.withOpacity(0.2),
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
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // Edit profile
                    },
                    icon: Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
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
                    title: "Wallet Balance",
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
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: Colors.white,
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
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build popular destinations carousel
  Widget _buildPopularDestinations() {
    final destinations = [
      {
        'name': 'Kathmandu',
        'image': 'assets/kathmandu.jpg',
        'buses': '45 buses'
      },
      {'name': 'Pokhara', 'image': 'assets/pokhara.jpg', 'buses': '32 buses'},
      {'name': 'Chitwan', 'image': 'assets/chitwan.jpg', 'buses': '18 buses'},
    ];

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Popular Destinations",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  // See all destinations
                },
                child: Text(
                  "See All",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 140.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final destination = destinations[index];
                return Container(
                  width: 200.w,
                  margin: EdgeInsets.only(right: 16.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Image background with error handling
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Image.asset(
                          destination['image']!,
                          height: 140.h,
                          width: 200.w,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 140.h,
                            width: 200.w,
                            color: Colors.grey.shade300,
                            child: Icon(
                              Icons.landscape,
                              size: 50.sp,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      // Destination info
                      Positioned(
                        bottom: 12.h,
                        left: 12.w,
                        right: 12.w,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              destination['name']!,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.directions_bus,
                                  color: Colors.white,
                                  size: 14.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  destination['buses']!,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Quick action buttons in grid layout
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'title': 'Book Ticket',
        'icon': Icons.confirmation_number_outlined,
        'color': Colors.blue
      },
      {
        'title': 'Track Bus',
        'icon': Icons.location_on_outlined,
        'color': Colors.red
      },
      {
        'title': 'My Tickets',
        'icon': Icons.receipt_long_outlined,
        'color': Colors.green
      },
      {
        'title': 'Offers',
        'icon': Icons.local_offer_outlined,
        'color': Colors.orange
      },
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
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
          SizedBox(height: 16.h),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return GestureDetector(
                onTap: () {
                  if (index == 0) {
                    context.go('/buslist');
                  }
                },
                child: Column(
                  children: [
                    Container(
                      width: 60.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: action['color'] as Color,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: (action['color'] as Color).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      action['title'] as String,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Featured services section
  Widget _buildFeaturedServices(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Our Services",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16.h),

          // Service Request
          _buildServiceCard(
            title: "Request a Ride",
            description: "Book a ride and track it in real-time",
            icon: Icons.directions_bus_filled_outlined,
            color: AppColors.primary,
            onTap: () {
              // Implement ride request feature
            },
          ),

          SizedBox(height: 16.h),

          // View ride history
          _buildServiceCard(
            title: "View Ride History",
            description: "Check your previous trips and bookings",
            icon: Icons.history,
            color: Colors.amber.shade700,
            onTap: () {
              // Implement ride history feature
            },
          ),

          SizedBox(height: 16.h),

          // Edit Profile
          _buildServiceCard(
            title: "Edit Profile",
            description: "Update your personal information",
            icon: Icons.person_outline,
            color: Colors.teal,
            onTap: () {
              // Implement profile editing
            },
          ),
        ],
      ),
    );
  }

  /// Service card widget
  Widget _buildServiceCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24.sp,
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
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.black54,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }
}
