import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../components/AppColors.dart';
import '../../../../components/CustomButton.dart';
import '../../../../core/constants.dart';
import '../../../../core/role.dart';
import '../../../Passenger/setting/providers/setting_provider.dart';
import '../../../authentication/login/presentation/login_screen.dart';
import '../../../authentication/login/providers/auth_provider.dart';
import '../../vehicle details/provider/vehicle_details_provider.dart';

class DriverSettingScreen extends ConsumerStatefulWidget {
  const DriverSettingScreen({super.key});

  @override
  ConsumerState<DriverSettingScreen> createState() =>
      _DriverSettingScreenState();
}

class _DriverSettingScreenState extends ConsumerState<DriverSettingScreen> {
  late UserRole _userType;

  @override
  void initState() {
    super.initState();
    _initializeUserRole();
    _fetchUserData();
    final userId = ref.read(authProvider).userId;
    if (userId != null) {
      ref.read(settingProvider.notifier).fetchUsers(userId).then((_) {
        final settingState = ref.read(settingProvider);
        if (settingState.users.isNotEmpty) {
          final vehicleId = settingState.users.first.vehicleId;
          ref.read(vehicleProvider.notifier).loadVehicle(vehicleId);
        }
      });
    }
  }

  void _initializeUserRole() {
    final authState = ref.read(authProvider); // Get stored role
    _userType =
        authState.currentRole ?? UserRole.DRIVER; // Default to DRIVER if null
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final settingState = ref.watch(settingProvider);
    final vehicleState = ref.watch(vehicleProvider);
    final hasVehicle = vehicleState.vehicle != null;
    print(hasVehicle);

    if (!authState.isLoggedIn) {
      return const LoginScreen();
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(settingState),
            _buildMenuOptions(hasVehicle),
          ],
        ),
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
  Widget _buildMenuOptions(bool hasVehicle) {
    double half = MediaQuery.of(context).size.width / 2.2; // Half width
    return Padding(
      padding: EdgeInsets.all(16.h),
      child: Column(
        children: [
          Row(
            children: [
              _buildUserTypeButton(UserRole.DRIVER),
              _buildUserTypeButton(UserRole.DRIVERUSER),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Column(
              children: [
                SizedBox(height: 16.h),
                hasVehicle
                    ? _menuButton(
                        CupertinoIcons.bus, 'View Vehicle', '/viewVehicle')
                    : _menuButton(
                        CupertinoIcons.bus, 'Add Vehicle', '/addVehicle'),
                SizedBox(height: 16.h),
                _menuButton(CupertinoIcons.person_3, 'About Us', '/addRoute'),
                SizedBox(height: 16.h),
                _menuButton(CupertinoIcons.exclamationmark_circle, 'Chat',
                    '/ChatGroup'),
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

  /// **Reusable user type button**
  Widget _buildUserTypeButton(UserRole type) {
    return Expanded(
      child: CustomButton(
        text: type == UserRole.DRIVER ? 'Driver' : 'Passenger',
        onPressed: () {
          setState(() {
            _userType = type;
          });

          // Update role temporarily (only in memory, not in database)
          ref.read(authProvider.notifier).setTemporaryRole(type);
        },
        color: _userType == type ? AppColors.primary : Colors.grey[300],
        textColor: _userType == type ? Colors.white : Colors.black,
      ),
    );
  }
}
