// Import required Flutter packages
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Import custom components and utilities
import '../../Components/AppColors.dart';
import '../../Components/CustomButton.dart';
import '../../Services/request_otp.dart';
import '../../routes/routes.dart';
import 'pass_change.dart';
import 'package:http/http.dart' as http;

/// Widget for OTP verification screen
class OTP extends StatefulWidget {
  const OTP({super.key, required this.email});

  final String email;

  @override
  State<OTP> createState() => _OTPState();
}

class _OTPState extends State<OTP> {
  // Controllers for the 4 OTP input fields
  final TextEditingController _fieldOne = TextEditingController();
  final TextEditingController _fieldTwo = TextEditingController();
  final TextEditingController _fieldThree = TextEditingController();
  final TextEditingController _fieldFour = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Configure app bar with back button
      appBar: AppBar(
        title: const Text('Verification'),
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
              // Title text
              Text(
                "Enter verification code",
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20.h),
              // Row of 4 OTP input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // First OTP digit field
                  SizedBox(
                    height: 68,
                    width: 64,
                    child: TextFormField(
                      controller: _fieldOne,
                      onChanged: (value) {
                        if (value.length == 1) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                      style: Theme.of(context).textTheme.titleLarge,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: AppColors.textSecondary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  // Second OTP digit field
                  SizedBox(
                    height: 68,
                    width: 64,
                    child: TextFormField(
                      controller: _fieldTwo,
                      onChanged: (value) {
                        if (value.length == 1) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                      style: Theme.of(context).textTheme.titleLarge,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: AppColors.textSecondary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  // Third OTP digit field
                  SizedBox(
                    height: 68,
                    width: 64,
                    child: TextFormField(
                      controller: _fieldThree,
                      onChanged: (value) {
                        if (value.length == 1) {
                          FocusScope.of(context).nextFocus();
                        }
                      },
                      style: Theme.of(context).textTheme.titleLarge,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: AppColors.textSecondary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  // Fourth OTP digit field
                  SizedBox(
                    height: 68,
                    width: 64,
                    child: TextFormField(
                      controller: _fieldFour,
                      onChanged: (value) {
                        if (value.length == 1) {
                          FocusScope.of(context).unfocus();
                        }
                      },
                      style: Theme.of(context).textTheme.titleLarge,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: AppColors.textSecondary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30.h),
              // Resend code option
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("If you didn't receive the code, ",
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12.sp)),
                GestureDetector(
                  onTap: () {
                    _resendOTP();
                  },
                  child: const Text("Resend",
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              SizedBox(height: 30.h),
              // Verify button
              CustomButton(
                text: 'Verify',
                onPressed: () {
                  _verifyOTP();
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

  /// Sends a request to verify the entered OTP
  ///
  /// Makes a POST request to the verifyOTP endpoint with the user's email
  /// and concatenated OTP digits. Validates that all OTP fields are filled.
  /// On success, navigates to password change screen.
  /// On failure, prints error message to console.
  Future<void> _verifyOTP() async {
    final url = Uri.parse('${Routes.route}verifyOTP');
    final body = {
      'email': widget.email,
      'otp':
          _fieldOne.text + _fieldTwo.text + _fieldThree.text + _fieldFour.text,
    };

    // Validate all OTP fields are filled
    if (_fieldOne.text.isEmpty ||
        _fieldTwo.text.isEmpty ||
        _fieldThree.text.isEmpty ||
        _fieldFour.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP')),
      );
      return;
    }

    // Send OTP verification request
    final response = await http.post(
      url,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );

    // Handle response
    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PassChange(email: widget.email)),
      );
    } else {
      print('Failed to verify OTP');
    }
  }

  Future<void> _resendOTP() async {
    if (widget.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await OTPService.requestOTP(widget.email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP has been resent')),
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
