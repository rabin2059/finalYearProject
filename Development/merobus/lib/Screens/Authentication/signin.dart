import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:merobus/Screens/Authentication/get_started.dart';
import 'package:merobus/Screens/Authentication/signup.dart';
import 'package:merobus/Screens/test.dart';
import 'package:merobus/models/loginModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Components/AppColors.dart';
import '../../Components/CustomButton.dart';
import '../../Components/CustomTextField.dart';
import '../../navigation/navigation.dart';
import '../../routes/routes.dart';
import 'package:http/http.dart' as http;

import 'forgot.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String token = '';

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loginUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final url = Uri.parse('${Routes.route}login');
      final body = {
        'email': emailController.text,
        'password': passwordController.text,
      };

      final response = await http.post(
        url,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'}, // Set headers for JSON
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final loginData = Login.fromJson(jsonDecode(response.body));
        token = loginData.token ?? '';
        prefs.setString('token', token);
        setState(() {});
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Navigation(dept: loginData.userRole)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid email or password")),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        'Welcome 👋',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 24.sp,
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ],
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
                  SizedBox(
                    height: 10.h,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Forgot()),
                          );
                        },
                        child: const Text(
                          'Forgot Password ?',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      SizedBox(
                        width: 10.w,
                      )
                    ],
                  ),
                  SizedBox(height: 20.h),
                  CustomButton(
                    text: 'Log In',
                    onPressed: () {
                      _loginUser();
                    },
                    height: 56.h,
                    width: 3237.w,
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
                  SizedBox(
                    height: 20.h,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignUp()),
                          );
                        }, // Handle the sign-up tap
                        child: const Text(
                          "Sign Up",
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
