import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../Components/AppColors.dart';
import '../../Components/CustomButton.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.dept});
  final int dept;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController licenseController = TextEditingController();
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dept == 1) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Profile"),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 20.w, top: 20.h),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 100.h,
                      width: 100.w,
                      child:
                          Image.asset('assets/profile.png', fit: BoxFit.cover),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 30.h,
                        width: 30.w,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18.r,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30.h),
              Row(
                children: [
                  Text(
                    "Personal Information",
                    style:
                        TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                children: [
                  LocalTextField("Full Name", nameController),
                  SizedBox(height: 10.h),
                  LocalTextField("Email Address", emailController),
                  SizedBox(height: 10.h),
                  LocalTextField("Phone Number", phoneController),
                  SizedBox(height: 10.h),
                  LocalTextField("Address", addressController),

                  SizedBox(height: 20.h),
                  CustomButton(
                    text: "Become a Driver",
                    color: AppColors.primary,
                    height: 50.h,
                    onPressed: () {},
                  ),
                  SizedBox(height: 10.h),
                  CustomButton(
                    text: "Update",
                    color: AppColors.buttonText,
                    textColor: AppColors.primary,
                    borderColor: AppColors.primary,
                    height: 50.h,
                    onPressed: () {},
                  ),
                  SizedBox(height: 10.h),
                  CustomButton(
                    text: "Delete Account",
                    color: AppColors.buttonText,
                    textColor: Colors.red,
                    borderColor: Colors.red,
                    height: 50.h,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Profile"),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 20.w, top: 20.h),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 100.h,
                      width: 100.w,
                      child:
                          Image.asset('assets/profile.png', fit: BoxFit.cover),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 30.h,
                        width: 30.w,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 18.r,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30.h),
              Row(
                children: [
                  Text(
                    "Personal Information",
                    style:
                        TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                children: [
                  LocalTextField("Full Name", nameController),
                  SizedBox(height: 10.h),
                  LocalTextField("Email Address", emailController),
                  SizedBox(height: 10.h),
                  LocalTextField("Phone Number", phoneController),
                  SizedBox(height: 10.h),
                  LocalTextField("Address", addressController),
                  SizedBox(height: 10.h),
                  LocalTextField("License Number", licenseController),
                  SizedBox(height: 20.h),
                  CustomButton(
                    text: "Update",
                    color: AppColors.buttonText,
                    textColor: AppColors.primary,
                    borderColor: AppColors.primary,
                    height: 50.h,
                    onPressed: () {},
                  ),
                  SizedBox(height: 10.h),
                  CustomButton(
                    text: "Delete Account",
                    color: AppColors.buttonText,
                    textColor: Colors.red,
                    borderColor: Colors.red,
                    height: 50.h,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  SizedBox LocalTextField(String hint, TextEditingController controller) {
    return SizedBox(
                  height: 40.h,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: hint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    controller: controller,
                  ),
                );
  }

  SizedBox StatusTextField(String hint, TextEditingController controller) {
    return SizedBox(
      height: 40.h,
      child: TextField(
        enabled: false,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.primary, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.primary, width: 1),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: const BorderSide(color: AppColors.primary, width: 1),
          ),
        ),
        controller: controller,
      ),
    );
  }
}
