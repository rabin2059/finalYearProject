// Import necessary Flutter and Material Design packages
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

// Import custom components and utilities
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../../components/AppColors.dart';
import '../../../../components/CustomButton.dart';
import '../../../../components/CustomTextField.dart';
import '../../../../core/constants.dart';

/// Widget for handling password change functionality
class PassChange extends StatefulWidget {
  const PassChange({super.key, required this.email});

  final String email;

  @override
  State<PassChange> createState() => _PassState();
}

class _PassState extends State<PassChange> {
  // Controllers for password input fields
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

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
            // New password section
            Row(
              children: [
                textNames('New Password'),
              ],
            ),
            SizedBox(height: 10.h),
            CustomTextField(
              hint: '********',
              prefixIcon: CupertinoIcons.lock,
              suffixIcon: CupertinoIcons.eye_slash,
              controller: passwordController,
            ),
            SizedBox(height: 20.h),
            // Confirm password section
            Row(
              children: [
                textNames('Confirm Password'),
              ],
            ),
            SizedBox(height: 10.h),
            CustomTextField(
              hint: '********',
              prefixIcon: CupertinoIcons.lock,
              suffixIcon: CupertinoIcons.eye_slash,
              controller: confirmPasswordController,
            ),
            SizedBox(height: 30.h),
            // Submit button to change password
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

  /// Helper method to create styled text labels
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

  /// Sends a request to the server to change the user's password
  ///
  /// Makes a POST request to the resetPassword endpoint with the user's email
  /// and new password. Validates that password fields are not empty.
  /// On success, navigates to sign in screen.
  /// On failure, shows error message to user.
  Future<void> _changePassword() async {
    final url = Uri.parse('$apiBaseUrl/resetPassword');
    final body = {
      'email': widget.email,
      'password': passwordController.text,
      'confirmPassword': confirmPasswordController.text,
    };

    // Validate password fields are not empty
    if (passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the password')),
      );
      return;
    }

    // Send password change request
    final response = await http.put(
      url,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );

    // Handle response
    if (response.statusCode == 200 || response.statusCode == 201) {
     context.go('/signup');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to change password')),
      );
    }
  }
}
