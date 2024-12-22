import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:merobus/Components/AppColors.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final IconData? icon; // Make the icon optional
  final IconData? suffixIcon;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? hintColor; // Add hintColor property
  final VoidCallback? onSuffixTap;
  final VoidCallback? onTap; // Add onTap callback
  final bool readOnly; // Add a readOnly property
  final ValueChanged<String>? onChanged; // Add onChanged callback

  const CustomTextField({
    super.key,
    required this.hint,
    this.icon, // Icon is optional now
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.grey,
    this.hintColor = const Color(0xffADADAD), // Default hint color
    this.onSuffixTap,
    this.onTap, // Initialize onTap callback
    this.readOnly = false, // Default to false
    this.onChanged, // Initialize onChanged callback
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
        readOnly: readOnly, // Set readOnly dynamically
        onChanged: onChanged, // Pass the onChanged callback
        onTap: onTap, // Pass the onTap callback
        decoration: InputDecoration(
          filled: true,
          fillColor: backgroundColor,
          prefixIcon: icon != null // Conditionally show prefixIcon
              ? Icon(icon, color: const Color(0xff858585))
              : null,
          hintText: hint,
          hintStyle: TextStyle(
            color: hintColor, // Use the custom hint color
          ),
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
