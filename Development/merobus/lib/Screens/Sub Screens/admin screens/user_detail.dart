import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:merobus/Components/AppColors.dart';
import 'package:merobus/Components/CustomButton.dart';
import 'package:merobus/Components/CustomTextField.dart';
import 'package:merobus/Screens/Main%20Screens/admin_screen.dart';
import 'package:merobus/models/user_model.dart';
import 'package:merobus/navigation/navigation.dart';
import 'package:merobus/routes/routes.dart';
import 'package:http/http.dart' as http;
import '../../../providers/get_user.dart';

class UserDetail extends StatefulWidget {
  const UserDetail({super.key, required this.id, required this.name});
  final String name;
  final int id;

  @override
  State<UserDetail> createState() => _UserDetailState();
}

class _UserDetailState extends State<UserDetail> {
  User? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Padding(
        padding: EdgeInsets.all(10.h),
        child: Column(
          children: [
            Container(
              height: 160.h,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/profile.png',
                fit: BoxFit.fill,
              ),
            ),
            titleName('Address'),
            CustomTextField(
              hint: '${userData?.address}',
              readOnly: true,
            ),
            SizedBox(
              height: 10.h,
            ),
            titleName('Phone'),
            CustomTextField(
              hint: '${userData?.phone}',
              readOnly: true,
            ),
            SizedBox(
              height: 10.h,
            ),
            titleName('License No.'),
            CustomTextField(
              hint: '${userData?.licenseNo}',
              readOnly: true,
            ),
            SizedBox(
              height: 10.h,
            ),
            titleName('Vehicle No.'),
            CustomTextField(
              hint: '${userData?.vehicleNo}',
              readOnly: true,
            ),
            SizedBox(
              height: 20.h,
            ),
            CustomButton(
              text: 'Approve',
              onPressed: () {
                _handleRequest('approve');
              },
              color: AppColors.primary,
              fontSize: 20.sp,
            ),
            SizedBox(
              height: 10.h,
            ),
            CustomButton(
              text: 'Decline',
              onPressed: () {
                _handleRequest('decline');
              },
              color: Colors.white,
              borderColor: AppColors.textPrimary,
              textColor: AppColors.primary,
              fontSize: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Row titleName(String name) {
    return Row(
      children: [
        Text(
          name,
          style: TextStyle(fontSize: 18.sp),
        )
      ],
    );
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

  void _handleRequest(String action) async {
    try {
      final url = Uri.parse('${Routes.route}validDriverRole');
      if (action == 'approve') {
        final body = {"id": widget.id, "status": "approved"};

        final response = await http.put(
          url,
          body: jsonEncode(body),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const Navigation(dept: 0)));
        } else {
          print("Failed");
        }
      } else if (action == 'decline') {
        final body = {"id": widget.id, "status": "decline"};

        final response = await http.put(
          url,
          body: jsonEncode(body),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const AdminScreen()));
        } else {
          print("Failed");
        }
      }
    } catch (e) {
      print(e);
    }
  }
}
