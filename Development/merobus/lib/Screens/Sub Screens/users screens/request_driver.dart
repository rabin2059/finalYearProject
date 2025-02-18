import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:merobus/Components/AppColors.dart';
import 'package:merobus/Components/CustomButton.dart';
import 'package:merobus/Components/CustomTextField.dart';
import 'package:merobus/models/user_model.dart';
import 'package:merobus/routes/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../providers/get_user.dart';

class RequestDriver extends StatefulWidget {
  const RequestDriver({super.key, required this.id, required this.status});
  final int id;
  final String status;

  @override
  State<RequestDriver> createState() => _RequestDriverState();
}

class _RequestDriverState extends State<RequestDriver> {
  final TextEditingController licenseController = TextEditingController();
  final TextEditingController vehicleController = TextEditingController();
  User? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  @override
  void dispose() {
    licenseController.dispose();
    vehicleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Driver'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: widget.status == "onHold"
                  ? _buildPendingRequestView()
                  : _buildRequestForm(),
            ),
    );
  }

  Widget _buildRequestForm() {
    return Column(
      children: [
        SizedBox(height: 30.h),
        SizedBox(
          height: 200.h,
          width: double.infinity,
          child: Image.asset(
            'assets/bus1.png',
            fit: BoxFit.cover,
          ),
        ),
        _titleName('License No.'),
        CustomTextField(
          hint: 'Enter your license no.',
          controller: licenseController,
        ),
        SizedBox(height: 10.h),
        _titleName('Vehicle No.'),
        CustomTextField(
          hint: 'Enter your vehicle no.',
          controller: vehicleController,
        ),
        SizedBox(height: 20.h),
        CustomButton(
          text: 'Submit',
          onPressed: _submitRequest,
          width: 300.w,
          color: AppColors.primary,
          fontSize: 20.sp,
        ),
      ],
    );
  }

  Widget _buildPendingRequestView() {
    if (userData == null) {
      return Center(
        child: Text(
          'User data not available.',
          style: TextStyle(fontSize: 18.sp, color: Colors.red),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(height: 30.h),
        SizedBox(
          height: 200.h,
          width: double.infinity,
          child: Image.asset(
            'assets/bus1.png',
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(height: 15.h),
        Row(
          children: [
            Text(
              'Status: ',
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.status,
              style: TextStyle(fontSize: 20.sp, color: AppColors.primary),
            ),
          ],
        ),
        SizedBox(height: 15.h),
        _titleName('License No.'),
        CustomTextField(
          hint: userData?.licenseNo ?? 'N/A',
          readOnly: true,
        ),
        SizedBox(height: 10.h),
        _titleName('Vehicle No.'),
        CustomTextField(
          hint: userData?.vehicleNo ?? 'N/A',
          readOnly: true,
        ),
      ],
    );
  }

  Row _titleName(String name) {
    return Row(
      children: [
        Text(
          name,
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _submitRequest() async {
    try {
      final url = Uri.parse('${Routes.route}requestRole');
      final body = {
        "id": widget.id,
        "licenseNo": licenseController.text,
        "vehicleNo": vehicleController.text
      };
      print(body);

      final response = await http.put(
        url,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _getUser() async {
    try {
      final data = await getUser(widget.id);
      if (data != null) {
        setState(() {
          userData = data;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
