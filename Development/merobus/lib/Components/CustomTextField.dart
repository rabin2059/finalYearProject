import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:merobus/Components/AppColors.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final IconData? suffixIcon;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onSuffixTap;

  const CustomTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.grey,
    this.onSuffixTap,
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
        decoration: InputDecoration(
          filled: true,
          fillColor: backgroundColor,
          prefixIcon: Icon(icon, color: const Color(0xff858585)),
          hintText: hint,
          hintStyle: const TextStyle(
              color: Color(0xffADADAD)), // Set text color to black
          suffixIcon: suffixIcon != null 
              ? InkWell(
                  onTap: onSuffixTap,
                  child: Icon(suffixIcon),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(52.r),
            borderSide: BorderSide(color: borderColor!), // Set border color
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(52.r),
            borderSide: BorderSide(color: borderColor!), // Set border color
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(52.r),
            borderSide: BorderSide(
                color: borderColor!, width: 2), // Highlight border on focus
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
        ),
      ),
    );
  }
}
