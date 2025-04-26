
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../components/AppColors.dart';
import '../../../../components/CustomButton.dart';
import '../../../../components/CustomTextField.dart';
import '../../../../core/constants.dart';

class PassChange extends StatefulWidget {
  const PassChange({super.key, required this.email});

  final String email;

  @override
  State<PassChange> createState() => _PassState();
}

class _PassState extends State<PassChange> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Configure app bar with back button
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
            CustomTextField(
              hint: '********',
              prefixIcon: CupertinoIcons.lock,
              suffixIcon: _isPasswordVisible ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
              controller: passwordController,
              obscureText: !_isPasswordVisible,
              onSuffixTap: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                textNames('Confirm Password'),
              ],
            ),
            SizedBox(height: 10.h),
            CustomTextField(
              hint: '********',
              prefixIcon: CupertinoIcons.lock,
              suffixIcon: _isConfirmPasswordVisible ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
              controller: confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              onSuffixTap: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                });
              },
            ),
            SizedBox(height: 30.h),
            CustomButton(
              text: 'Change Password',
              onPressed: () {
                _changePassword();
              },
              color: AppColors.primary,
              fontSize: 16.sp,
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
  Future<void> _changePassword() async {
    final url = Uri.parse('$apiBaseUrl/resetPassword');
    final body = {
      'email': widget.email,
      'password': passwordController.text,
      'confirmPassword': confirmPasswordController.text,
    };

    if (passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the password')),
      );
      return;
    }

    final response = await http.put(
      url,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );

    // Handle response
    if (response.statusCode == 200 || response.statusCode == 201) {
     context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to change password')),
      );
    }
  }
}
