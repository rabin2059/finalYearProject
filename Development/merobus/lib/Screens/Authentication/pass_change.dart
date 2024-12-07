import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../Components/AppColors.dart';
import '../../Components/CustomButton.dart';
import '../../Components/CustomTextField.dart';
import 'signin.dart';

class PassChange extends StatefulWidget {
  const PassChange({super.key});

  @override
  State<PassChange> createState() => _PassState();
}

class _PassState extends State<PassChange> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(left: 20.w, right: 20.w),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Row(
              children: [
                textNames('New Password'),
              ],
            ),
            SizedBox(height: 10.h),
            const CustomTextField(
              hint: '********',
              icon: CupertinoIcons.lock,
              suffixIcon: CupertinoIcons.eye_slash,
              // controller: usernameController,
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                textNames('Confirm Password'),
              ],
            ),
            SizedBox(height: 10.h),
            const CustomTextField(
              hint: '********',
              icon: CupertinoIcons.lock,
              suffixIcon: CupertinoIcons.eye_slash,
              // controller: usernameController,
            ),
            SizedBox(height: 30.h),
            CustomButton(
              text: 'Change Password',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignIn()),
                );
              },
              color: AppColors.primary,
              fontSize: 16.sp,
              borderRadius: 30.r,
            ),
          ],
        ),
      ),
    );
  }

  Text textNames(String data) {
    return Text(
      data,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 16.sp,
      ),
    );
  }
}
