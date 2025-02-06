import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/components/AppColors.dart';
import 'package:frontend/components/CustomButton.dart';
import 'package:frontend/components/CustomTextField.dart';
import 'package:image_picker/image_picker.dart';

import '../../authentication/providers/auth_provider.dart';
import '../../setting/providers/setting_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // File? _image;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final settingState = ref.watch(settingProvider);

    return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              }),
        ),
        body: Center(
          child: Column(children: [
            Container(
                height: 106.h,
                width: 106.h,
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 53.h,
                      backgroundColor: Colors.grey[200],
                      child: settingState.users.isNotEmpty &&
                              settingState.users[0].images != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(50.0),
                              child: Image.network(
                                settingState.users[0].images!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset("assets/profile.png"),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 30.h,
                        width: 30.h,
                        decoration: BoxDecoration(
                          color: Color(0xffF1F1F1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: AppColors.primary,
                          size: 20.h,
                        ),
                      ),
                    ),
                  ],
                )),
            SizedBox(
              height: 20.h,
            ),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              SizedBox(
                width: 28.w,
              ),
              Text("Name")
            ]),
            SizedBox(
              height: 10.h,
            ),
            CustomTextField(
              hint: settingState.users.isNotEmpty
                  ? settingState.users[0].username
                  : "Name",
              hintColor: Colors.black87,
              controller: _usernameController,
              borderColor: Colors.transparent,
              backgroundColor: Color(0xFFF1F1F1),
            ),
            SizedBox(
              height: 10.h,
            ),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              SizedBox(
                width: 28.w,
              ),
              Text("Email")
            ]),
            SizedBox(
              height: 10.h,
            ),
            CustomTextField(
              hint: settingState.users.isNotEmpty
                  ? settingState.users[0].email
                  : "Email",
              hintColor: Colors.black87,
              controller: _emailController,
              borderColor: Colors.transparent,
              backgroundColor: Color(0xFFF1F1F1),
            ),
            SizedBox(
              height: 10.h,
            ),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              SizedBox(
                width: 28.w,
              ),
              Text("Phone Number")
            ]),
            SizedBox(
              height: 10.h,
            ),
            CustomTextField(
              hint: settingState.users.isNotEmpty
                  ? settingState.users[0].phone!
                  : "Phone",
              hintColor: Colors.black87,
              controller: _phoneController,
              borderColor: Colors.transparent,
              backgroundColor: Color(0xFFF1F1F1),
            ),
            SizedBox(
              height: 10.h,
            ),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              SizedBox(
                width: 28.w,
              ),
              Text("Address")
            ]),
            SizedBox(
              height: 10.h,
            ),
            CustomTextField(
              hint: settingState.users.isNotEmpty
                  ? settingState.users[0].address!
                  : "Address",
              hintColor: Colors.black87,
              controller: _addressController,
              borderColor: Colors.transparent,
              backgroundColor: Color(0xFFF1F1F1),
            ),
            SizedBox(
              height: 30.h,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomButton(
                  text: 'Cancel',
                  onPressed: () {},
                  color: Colors.red,
                  textColor: Colors.white,
                  boxShadow: const [],
                  width: 120.w,
                  height: 42.h,
                ),
                SizedBox(width: 20.w),
                CustomButton(
                  text: 'Save',
                  onPressed: () {},
                  color: AppColors.primary,
                  textColor: Colors.white,
                  boxShadow: const [],
                  width: 120.w,
                  height: 42.h,
                ),
                SizedBox(width: 28.w),
              ],
            ),
          ]),
        ));
  }
}
