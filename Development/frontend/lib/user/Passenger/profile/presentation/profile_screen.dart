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

import '../../../authentication/login/providers/auth_provider.dart';
import '../../setting/providers/setting_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  File? _image;
  late String originalUsername;
  late String originalEmail;
  late String originalPhone;
  late String originalAddress;
  late String? originalImageUrl;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _hasChanged = false; // ✅ Track changes

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _addListeners(); // ✅ Listen for changes in text fields
  }

  /// **Loads User Data into TextFields & Stores Initial Values**
  void _loadUserData() {
    final settingState = ref.read(settingProvider);

    if (settingState.users.isNotEmpty) {
      final user = settingState.users[0];

      originalUsername = user.username ?? "";
      originalEmail = user.email ?? "";
      originalPhone = user.phone ?? "";
      originalAddress = user.address ?? "";
      originalImageUrl = user.images;

      _usernameController.text = originalUsername;
      _emailController.text = originalEmail;
      _phoneController.text = originalPhone;
      _addressController.text = originalAddress;
    }
  }

  /// **Attach Listeners to Detect Changes in Text Fields**
  void _addListeners() {
    _usernameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
    _addressController.addListener(_checkForChanges);
  }

  /// **Check if any field has changed**
  void _checkForChanges() {
    setState(() {
      _hasChanged = _usernameController.text != originalUsername ||
          _emailController.text != originalEmail ||
          _phoneController.text != originalPhone ||
          _addressController.text != originalAddress ||
          _image != null; // ✅ Check if a new image is selected
    });
  }

  /// **Pick an Image**
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _hasChanged = true; // ✅ Mark change when image is picked
      });
    }
  }

  /// **Update Profile**
  Future<void> _updateProfile() async {
    if (!_hasChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No changes were made")),
      );
      return;
    }

    final authState = ref.read(authProvider);
    final userId = authState.userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("User ID is missing. Please log in again.")),
      );
      return;
    }

    try {
      await ref.read(profileProvider.notifier).updateProfile(
            userId,
            _usernameController.text,
            _emailController.text,
            _phoneController.text,
            _addressController.text,
            _image,
          );

      if (mounted) {
        ref.watch(settingProvider.notifier).fetchUsers(userId);
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      radius: 53.h,
                      backgroundColor: Colors.grey[200],
                      child: ClipOval(
                        child: _image != null
                            ? Image.file(
                                _image!,
                                fit: BoxFit.cover,
                                width: 106.h,
                                height: 106.h,
                              )
                            : (originalImageUrl != null)
                                ? Image.network(
                                    imageUrl + originalImageUrl!,
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
                                    "assets/profile.png",
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
              _buildTextField("Name", _usernameController),
              _buildTextField("Email", _emailController),
              _buildTextField("Phone Number", _phoneController),
              _buildTextField("Address", _addressController),
              SizedBox(height: 30.h),

              // Buttons Row
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
                    onPressed: _hasChanged
                        ? _updateProfile
                        : () {}, // ✅ Enable dynamically
                    color: _hasChanged ? AppColors.primary : Colors.grey,
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

  /// **Helper function to build TextFields**
  Widget _buildTextField(String label, TextEditingController controller) {
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
          hint: label,
          controller: controller,
          borderColor: Colors.transparent,
          backgroundColor: const Color(0xFFF1F1F1),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }
}
