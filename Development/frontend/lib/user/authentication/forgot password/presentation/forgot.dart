// Import necessary Flutter and Material Design packages
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../components/AppColors.dart';
import '../../../../components/CustomButton.dart';
import '../../../../components/CustomTextField.dart';
import '../../../../data/services/request_otp.dart';
import '../../otp/presentation/otp.dart';

// Import custom components and utilities

/// Widget for handling forgot password functionality
class Forgot extends StatefulWidget {
  const Forgot({super.key});

  @override
  State<Forgot> createState() => _ForgotState();
}

class _ForgotState extends State<Forgot> {
  // Controller for email input field
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Configure app bar with back button
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
              // Instructions text for user
              Text(
                "Enter your email address",
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(
                height: 20.h,
              ),
              // Email input field
              CustomTextField(
                hint: 'rai@gmail.co',
                prefixIcon: CupertinoIcons.mail,
                controller: emailController,
              ),
              SizedBox(height: 30.h),
              // Submit button to request OTP
              CustomButton(
                text: 'Send',
                onPressed: () {
                  _reqOTP();
                },
                color: AppColors.primary,
                fontSize: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reqOTP() async {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await OTPService.requestOTP(emailController.text);
      
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => OTP(email: emailController.text)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
