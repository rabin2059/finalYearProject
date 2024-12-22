import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:merobus/Screens/Sub%20Screens/users%20screens/request_driver.dart';
import 'package:merobus/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Components/AppColors.dart';
import '../../../Components/CustomButton.dart';
import '../../../providers/get_user.dart';

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
  bool _isLoading = true;
  User? userData;

  @override
  void initState() {
    _getuser();
    super.initState();
  }

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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
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
                  LocalTextField(
                      'Namee', "${userData!.username}", nameController),
                  SizedBox(height: 10.h),
                  LocalTextField(
                      'Email', "${userData!.email}", emailController),
                  SizedBox(height: 10.h),
                  LocalTextField('Phone',
                      "${userData!.phone ?? ""}", phoneController),
                  SizedBox(height: 10.h),
                  LocalTextField('Addres', "${userData!.address ?? ""}",
                      addressController),
                  SizedBox(height: 20.h),
                  CustomButton(
                    text: "Become a Driver",
                    color: AppColors.primary,
                    height: 50.h,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RequestDriver(
                                  id: userData!.id,
                                  status: '${userData!.status}')));
                    },
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
                  LocalTextField(
                      'Name', "${userData!.username}", nameController),
                  SizedBox(height: 10.h),
                  LocalTextField(
                      'Email', "${userData!.email}", emailController),
                  SizedBox(height: 10.h),
                  LocalTextField('Phone',
                      "${userData!.phone ?? ""}", phoneController),
                  SizedBox(height: 10.h),
                  LocalTextField('Address',
                      "${userData!.address ?? ""}", addressController),
                  SizedBox(height: 10.h),
                  StatusTextField('Licence No.', "${userData!.licenseNo}"),
                  SizedBox(
                    height: 10.h,
                  ),
                  StatusTextField('Vehicle No.', "${userData!.vehicleNo}"),
                  SizedBox(
                    height: 10.h,
                  ),
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

  Row StatusTextField(String title, String hint) {
    return Row(
      children: [
        Text(
          "$title: ",
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(
          height: 40.h,
          width: 250.w,
          child: TextField(
            enabled: false,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1),
              ),
            ),
            controller: emailController,
          ),
        )
      ],
    );
  }

  Row LocalTextField(
      String title, String hint, TextEditingController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "$title: ",
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(
          height: 40.h,
          width: 250.w,
          child: TextField(
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            controller: controller,
          ),
        )
      ],
    );
  }

  Future<void> _getuser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        print("No token found");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['userId'];
      final data = await getUser(userId);

      if (data != null) {
        setState(() {
          userData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e); // Handle error appropriately
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateUser() async {
    try {} catch (e) {}
  }
}
