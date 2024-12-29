import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:merobus/Components/AppColors.dart';
import 'package:merobus/Components/CustomButton.dart';

class GetStarted extends StatefulWidget {
  const GetStarted({super.key});

  @override
  State<GetStarted> createState() => _GetStartedState();
}

class _GetStartedState extends State<GetStarted> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 12.w,
              ),
              SizedBox(height: 44.h, child: Image.asset('assets/logo.png')),
            ],
          ),
          SizedBox(
            height: 151.h,
          ),
          SizedBox(
              height: 180.h,
              width: 310.w,
              child: Image.asset('assets/bus.png')),
          SizedBox(
            height: 95.h,
          ),
          Text(
            'Find the exact ride for \n your destination',
            style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                height: 1.3.h,
                color: Colors.black),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 10.h,
          ),
          Text(
            "The location of the bus you want at \n your pocket",
            style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.8.h),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 24.h,
          ),
          CustomButton(
            text: "Sign In",
            onPressed: () {
              context.push('/login');
            },
            color: AppColors.primary,
            textColor: Colors.white,
            width: 366.w,
            height: 48.h,
            fontSize: 20.sp,
          ),
          SizedBox(
            height: 10.h,
          ),
          CustomButton(
            text: "Sign Up",
            onPressed: () {
              context.push('/signup');
            },
            color: Colors.white,
            textColor: AppColors.primary,
            width: 366.w,
            height: 48.h,
            fontSize: 20.sp,
          ),
        ],
      )),
    );
  }
}
