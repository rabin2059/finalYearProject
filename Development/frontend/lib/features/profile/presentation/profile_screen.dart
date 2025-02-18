import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/components/AppColors.dart';
import 'package:frontend/components/CustomButton.dart';
import 'package:frontend/components/CustomTextField.dart';
import 'package:frontend/core/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../authentication/providers/auth_provider.dart';
import '../../setting/presentation/setting_screen.dart';
import '../../setting/providers/setting_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  File? _image; // Holds the selected image file
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  /// **Pick an Image**
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Set the picked image
      });
    }
  }

  /// **Update Profile**
  Future<void> _updateProfile() async {
    final userNotifier = ref.read(profileProvider.notifier);
    final authState = ref.read(authProvider);
    final userId = authState.userId;

    try {
      await userNotifier
          .updateProfile(
        userId!,
        _usernameController.text,
        _emailController.text,
        _phoneController.text,
        _addressController.text,
        _image, // Pass the image if selected, otherwise null
      )
          .then((_) {
        context.pushNamed('/settings'); // Navigate to settings after saving
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final settingState = ref.watch(settingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              // Profile Picture Section
              Container(
                height: 106.h,
                width: 106.h,
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 53.h, // Adjust the radius as needed
                      backgroundColor:
                          Colors.grey[200], // Fallback background color
                      child: ClipOval(
                        child: _image != null
                            ? Image.file(
                                _image!, // Show picked image
                                fit: BoxFit.cover,
                                width: 106.h,
                                height: 106.h,
                              )
                            : (settingState.users.isNotEmpty &&
                                    settingState.users[0].images != null)
                                ? Image.network(
                                    imageUrl + settingState.users[0].images!,
                                    fit: BoxFit.cover,
                                    width: 106.h,
                                    height: 106.h,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        "assets/profile.png",
                                        fit: BoxFit.cover,
                                        width: 106.h,
                                        height: 106.h,
                                      );
                                    },
                                  )
                                : Image.asset(
                                    "assets/profile.png", // Default profile image
                                    fit: BoxFit.cover,
                                    width: 106.h,
                                    height: 106.h,
                                  ),
                      ),
                    ),
                    // Camera Icon for Picking Image
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 30.h,
                        width: 30.h,
                        decoration: const BoxDecoration(
                          color: Color(0xffF1F1F1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _pickImage,
                          icon: Icon(
                            Icons.camera_alt,
                            color: AppColors.primary,
                            size: 20.h,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              _buildTextField(
                "Name",
                _usernameController,
                settingState.users.isNotEmpty
                    ? settingState.users[0].username
                    : "Name",
                TextInputType.text, // Default text input for names
              ),
              _buildTextField(
                "Email",
                _emailController,
                settingState.users.isNotEmpty
                    ? settingState.users[0].email
                    : "Email",
                TextInputType.emailAddress, // Email-specific keyboard
              ),
              _buildTextField(
                "Phone Number",
                _phoneController,
                settingState.users.isNotEmpty
                    ? settingState.users[0].phone!
                    : "Phone",
                TextInputType.phone, // Phone keyboard
              ),
              _buildTextField(
                "Address",
                _addressController,
                settingState.users.isNotEmpty
                    ? settingState.users[0].address!
                    : "Address",
                TextInputType.text, // Default text input
              ),
              SizedBox(height: 30.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(
                    text: 'Cancel',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    color: Colors.red,
                    textColor: Colors.white,
                    boxShadow: const [],
                    width: 120.w,
                    height: 42.h,
                  ),
                  SizedBox(width: 20.w),
                  CustomButton(
                    text: 'Save',
                    onPressed: _updateProfile, // Call updateProfile on save
                    color: AppColors.primary,
                    textColor: Colors.white,
                    boxShadow: const [],
                    width: 120.w,
                    height: 42.h,
                  ),
                  SizedBox(width: 28.w),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// **Helper function to build TextFields**
Widget _buildTextField(
  String label,
  TextEditingController controller,
  String hint,
  TextInputType inputType, // Made non-nullable
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(width: 28.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      SizedBox(height: 10.h),
      CustomTextField(
        hint: hint,
        hintColor: Colors.black45,
        controller: controller,
        borderColor: Colors.transparent,
        backgroundColor: const Color(0xFFF1F1F1),
        keyboardType: inputType, // Pass the keyboard type
      ),
      SizedBox(height: 10.h),
    ],
  );
}
