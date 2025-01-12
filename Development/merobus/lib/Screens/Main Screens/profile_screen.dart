import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:merobus/Components/AppColors.dart';
import 'package:merobus/Components/CustomButton.dart';
import 'package:merobus/Screens/Sub%20Screens/users%20screens/edit_profile.dart';
import 'package:merobus/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/get_user.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({super.key, required this.dept});
  final int dept;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  User? userData; // userData is nullable as it can be null initially

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  @override
  Widget build(BuildContext context) {
    // Display loading spinner while fetching user data
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Return the profile screen UI
    if (widget.dept == 1) {
      return Scaffold(
        body: Column(
          children: [
            Container(
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
                          decoration:
                              const BoxDecoration(shape: BoxShape.circle),
                          child: Image.asset('assets/profile.png'),
                        ),
                        SizedBox(width: 20.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData?.username ?? 'UserName',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w700),
                            ),
                            Text(
                              userData?.phone ?? '98127384574',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                ),
                                Text(
                                  userData?.address ?? 'Itahari, Bishnu-Chowk',
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => UpdateUserScreen(userId: userData?.id ?? 0)),
                            );
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
            ),
            Padding(
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
                        navButtons(CupertinoIcons.bus, 'Be a Driver'),
                        SizedBox(height: 16.h),
                        navButtons(CupertinoIcons.person_3, 'About Us'),
                        SizedBox(height: 16.h),
                        navButtons(
                            CupertinoIcons.exclamationmark_circle, 'Help'),
                        SizedBox(height: 16.h),
                        navButtons(Icons.settings, 'Setting'),
                        SizedBox(height: 16.h),
                        navButtons(Icons.key, 'Change Password'),
                        SizedBox(height: 16.h),
                        navButtons(Icons.logout, 'Log Out'),
                        SizedBox(height: 16.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return const Scaffold(); // Fallback for different dept
    }
  }

  GestureDetector navButtons(IconData icons, String title) {
    return GestureDetector(
      onTap: () {},
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
                    borderRadius: BorderRadius.circular(4.r)),
                child: Padding(
                  padding: EdgeInsets.all(3.h),
                  child: Icon(icons),
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

  // Fetch user data from SharedPreferences and JWT
  Future<void> _getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        print("No token found");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['userId'];
      final data = await getUser(userId);

      if (data != null) {
        setState(() {
          userData = data; // Assign user data
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e); // Handle error appropriately
      setState(() {
        _isLoading = false;
      });
    }
  }
}
