import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:merobus/Components/AppColors.dart';
import 'package:merobus/Components/CustomButton.dart';
import 'package:merobus/Components/CustomTextField.dart';
import 'package:merobus/Screens/Authentication/signin.dart';
import 'package:http/http.dart' as http;
import '../../routes/routes.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void createUser() async {
    try {
      final url = Uri.parse('${Routes.route}signUp');
      final body = {
        'username': usernameController.text,
        'email': emailController.text,
        'password': passwordController.text,
        'confirmPassword': confirmPasswordController.text,
      };

      final response = await http.post(
        url,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'}, // Set headers for JSON
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(responseData['message'] ?? 'User created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorData['message'] ?? 'Failed to create user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print(e);
    }
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
                    icon: CupertinoIcons.mail,
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
                    icon: CupertinoIcons.mail,
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
                    icon: CupertinoIcons.lock,
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
                    icon: CupertinoIcons.lock,
                    suffixIcon: CupertinoIcons.eye_slash,
                    keyboardType: TextInputType.visiblePassword,
                    controller: confirmPasswordController,
                  ),
                  SizedBox(height: 20.h),
                  CustomButton(
                    text: 'Sign Up',
                    onPressed: () {
                      createUser();
                    },
                    height: 56.h,
                    width: 327.w,
                    color: AppColors.primary,
                    borderRadius: 28.r,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignIn()),
                          );
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
