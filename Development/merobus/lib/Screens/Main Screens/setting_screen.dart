import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:merobus/Screens/Sub%20Screens/users%20screens/profile_screen.dart';
import 'package:merobus/models/user_model.dart';
import 'package:merobus/providers/get_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Components/AppColors.dart';
import '../Authentication/signin.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key, required this.dept});
  final int dept;

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  String? userName;
  bool isLoading = true;

  @override
  void initState() {
    _getUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (widget.dept == 1) {
      return Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16.r),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 100.h,
                  width: 100.w,
                  child: Image.asset('assets/profile.png', fit: BoxFit.cover),
                ),
                SizedBox(height: 10.h),
                Text(
                  userName ?? "User Name",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xff828282),
                  ),
                ),
                SizedBox(height: 15.h),
                _profileButton(
                  CupertinoIcons.profile_circled,
                  "Profile",
                  ProfileScreen(dept: widget.dept),
                ),
                SizedBox(height: 15.h),
                _profileButton(
                  CupertinoIcons.person_3_fill,
                  "About Us",
                  const ProfileScreen(dept: 1),
                ),
                SizedBox(height: 15.h),
                _profileButton(
                  CupertinoIcons.question,
                  "Help",
                  const ProfileScreen(dept: 1),
                ),
                SizedBox(height: 15.h),
                _profileButton(
                  Icons.feedback,
                  "Feedback",
                  const ProfileScreen(dept: 1),
                ),
                SizedBox(height: 15.h),
                _profileButton(Icons.logout, "Logout", const SignIn()),
              ],
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16.r),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 100.h,
                  width: 100.w,
                  child: Image.asset('assets/profile.png', fit: BoxFit.cover),
                ),
                SizedBox(
                  height: 10.h,
                ),
                Text(userName ?? "User Name",
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xff828282))),
                SizedBox(height: 15.h),
                _profileButton(CupertinoIcons.profile_circled, "Profile",
                    ProfileScreen(dept: widget.dept)),
                SizedBox(height: 15.h),
                _profileButton(CupertinoIcons.person_3_fill, "About Us",
                    const ProfileScreen(dept: 1)),
                SizedBox(height: 15.h),
                _profileButton(CupertinoIcons.question, "Help",
                    const ProfileScreen(dept: 1)),
                SizedBox(height: 15.h),
                _profileButton(
                    Icons.feedback, "Feedback", const ProfileScreen(dept: 1)),
                SizedBox(height: 15.h),
                _profileButton(Icons.logout, "Logout", const SignIn()),
              ],
            ),
          ),
        ),
      );
    }
  }

  GestureDetector _profileButton(IconData icon, String text, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          children: [
            Icon(icon),
            SizedBox(width: 15.w),
            Text(
              text,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xff828282),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      print(token);

      if (token == null || token.isEmpty) {
        throw Exception("No token found");
      }

      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['userId'];
      final data = await getUser(userId);

      if (data == null) {
        throw Exception("Failed to fetch user data");
      }

      setState(() {
        userName = data.username; // Update this to match your API response
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }
}
