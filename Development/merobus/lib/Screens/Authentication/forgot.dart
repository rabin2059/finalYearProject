import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../Components/AppColors.dart';
import '../../Components/CustomButton.dart';
import '../../Components/CustomTextField.dart';
import 'otp.dart';

class Forgot extends StatefulWidget {
  const Forgot({super.key});

  @override
  State<Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.only(left: 20.w, right: 20.w),
          child: Column(
            children: [
              SizedBox(height: 20.h),
              Text(
                "Enter your email address",
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(
                height: 20.h,
              ),
              const CustomTextField(
                hint: 'rai@gmail.co',
                icon: CupertinoIcons.mail,
                // controller: emailController,
              ),
              SizedBox(height: 30.h),
              CustomButton(
                text: 'Send',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OTP()),
                  );
                },
                color: AppColors.primary,
                fontSize: 16.sp,
                borderRadius: 30.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
