import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:merobus/Components/AppColors.dart';
import 'package:cupertino_icons/cupertino_icons.dart'; // Import Cupertino Icons

class CustomTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final IconData? suffixIcon;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      width: 335.w,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: Colors.black), // Set text color to black
        decoration: InputDecoration(
          prefixIcon: Icon(icon), // Use Cupertino Icons here
          hintText: hint,
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon)
              : null, // Use Cupertino Icons here
          fillColor: AppColors.primary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(52.r),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
        ),
      ),
    );
  }
}
