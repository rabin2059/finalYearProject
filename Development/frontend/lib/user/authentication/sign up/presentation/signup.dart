import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../components/AppColors.dart';
import '../../../../components/CustomButton.dart';
import '../../../../components/CustomTextField.dart';
import '../../../../core/constants.dart';

class SignUp extends ConsumerStatefulWidget {
  const SignUp({super.key});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends ConsumerState<SignUp> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;

  Future<void> _createUser() async {
    try {
      final url = Uri.parse('$apiBaseUrl/signUp');
      final body = {
        'username': usernameController.text,
        'email': emailController.text,
        'password': passwordController.text,
        'confirmPassword': confirmPasswordController.text,
      };

      if (passwordController.text != confirmPasswordController.text) {
        showSnackBar(context, 'Passwords do not match');
        return;
      }

      final response = await http.post(url,
          body: json.encode(body),
          headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200 || response.statusCode == 201) {
        showSnackBar(context, 'User created successfully');
        context.go('/login');
      } else {
        showSnackBar(context, 'Failed to create user: ${response.body}');
      }
    } catch (e) {
      print('Error creating user: $e');
    }
  }

  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 250.h,
              child: Stack(
                children: [
                  Image.asset(
                    'assets/bus1.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.white.withOpacity(1),
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.1), // More transparent
                          Colors.white.withOpacity(0),
                        ],
                        stops: const [
                          0.0,
                          0.3,
                          0.6,
                          1.0
                        ], // Control the density
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 16.w, right: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        'Create Your Account',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 20.sp,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      textNames('Username'),
                    ],
                  ),
                  CustomTextField(
                    hint: 'Enter Username',
                    prefixIcon: CupertinoIcons.mail,
                    controller: usernameController,
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      textNames('Email'),
                    ],
                  ),
                  CustomTextField(
                    hint: 'Enter your email',
                    prefixIcon: CupertinoIcons.mail,
                    controller: emailController,
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      textNames('Password'),
                    ],
                  ),
                  CustomTextField(
                    hint: 'Enter your password',
                    prefixIcon: CupertinoIcons.lock,
                    suffixIcon: CupertinoIcons.eye_slash,
                    keyboardType: TextInputType.visiblePassword,
                    controller: passwordController,
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      textNames('Confirm Password'),
                    ],
                  ),
                  CustomTextField(
                    hint: 'Confirm your password',
                    prefixIcon: CupertinoIcons.lock,
                    suffixIcon: CupertinoIcons.eye_slash,
                    keyboardType: TextInputType.visiblePassword,
                    controller: confirmPasswordController,
                  ),
                  SizedBox(height: 20.h),
                  CustomButton(
                    text: 'Sign Up',
                    onPressed: () {
                      _createUser();
                    },
                    height: 56.h,
                    width: 327.w,
                    color: AppColors.primary,
                    fontSize: 17.sp,
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(
                          color: AppColors.textSecondary,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Or',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 15.sp),
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          color: AppColors.textSecondary,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account? ",
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.go('/login');
                        }, // Handle the sign-up tap
                        child: const Text(
                          "Log In",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                AppColors.primary, // Change color for emphasis
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
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
