import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:merobus/Screens/Sub%20Screens/profile_screen.dart';

import '../../Components/AppColors.dart';
import '../Authentication/signin.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key, required this.dept});
  final int dept;

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
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
                SizedBox(
                  height: 10.h,
                ),
                Text("User Name",
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xff828282))),
                SizedBox(height: 15.h),
                ProfileButtons(CupertinoIcons.profile_circled, "Profile",
                    const ProfileScreen(dept: 1)),
                SizedBox(height: 15.h),
                ProfileButtons(CupertinoIcons.person_3_fill, "About Us",
                    const ProfileScreen(dept: 1)),
                SizedBox(height: 15.h),
                ProfileButtons(CupertinoIcons.question, "Help",
                    const ProfileScreen(dept: 1)),
                SizedBox(height: 15.h),
                ProfileButtons(
                    Icons.feedback, "Feedback", const ProfileScreen(dept: 1)),
                SizedBox(height: 15.h),
                ProfileButtons(
                    Icons.logout, "Logout", const SignIn()),
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
                Text("User Name",
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xff828282))),
                SizedBox(height: 15.h),
                ProfileButtons(CupertinoIcons.profile_circled, "Profile",
                    ProfileScreen(dept: widget.dept)),
                SizedBox(height: 15.h),
                ProfileButtons(CupertinoIcons.person_3_fill, "About Us",
                    const ProfileScreen(dept: 1)),
                SizedBox(height: 15.h),
                ProfileButtons(CupertinoIcons.question, "Help",
                    const ProfileScreen(dept: 1)),
                SizedBox(height: 15.h),
                ProfileButtons(
                    Icons.feedback, "Feedback", const ProfileScreen(dept: 1)),
                SizedBox(height: 15.h),
                ProfileButtons(
                    Icons.logout, "Logout", const SignIn()),
              ],
            ),
          ),
        ),
      );
    }
  }

  GestureDetector ProfileButtons(IconData icon, String text, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => screen));
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
            Text(text,
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xff828282))),
          ],
        ),
      ),
    );
  }
}
