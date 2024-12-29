import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:merobus/Components/AppColors.dart';
import 'package:merobus/Components/CustomButton.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: Image.asset('assets/profile.png'),
                      ),
                      SizedBox(
                        width: 20.w,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rabin Rai',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700),
                          ),
                          const Text(
                            '98127384574',
                            style: TextStyle(color: Colors.white),
                          ),
                          const Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.white,
                              ),
                              Text(
                                'Itahari, Bishnu-Chowk',
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CustomButton(
                        text: 'Edit Profile',
                        onPressed: () {},
                        width: 110.w,
                        height: 30.h,
                        fontSize: 12.sp,
                        color: AppColors.primary,
                        borderColor: Colors.white,
                        boxShadow: const [],
                      ),
                    ],
                  )
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
                      SizedBox(height: 16.h,),
                      navButtons(CupertinoIcons.bus, 'Be a Driver'),
                      SizedBox(
                        height: 16.h,
                      ),
                      navButtons(CupertinoIcons.person_3, 'About Us'),
                      SizedBox(
                        height: 16.h,
                      ),
                      navButtons(CupertinoIcons.exclamationmark_circle, 'Help'),
                      SizedBox(
                        height: 16.h,
                      ),
                      navButtons(Icons.settings, 'Setting'),
                      SizedBox(
                        height: 16.h,
                      ),
                      navButtons(Icons.key, 'Change Password'),
                      SizedBox(
                        height: 16.h,
                      ),
                      navButtons(Icons.logout, 'Log Out'),
                      SizedBox(
                        height: 16.h,
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
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
                  )),
              SizedBox(
                width: 10.w,
              ),
              Text(
                '$title',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              )
            ],
          ),
          const Icon(CupertinoIcons.forward)
        ],
      ),
    );
  }
}
