import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? hintColor;
  final Color? textColor;
  final VoidCallback? onSuffixTap;
  final VoidCallback? onTap;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final int? maxLines;
  final TextCapitalization textCapitalization;

  const CustomTextField({
    super.key,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.grey,
    this.hintColor = const Color(0xffADADAD),
    this.textColor = Colors.black,
    this.onSuffixTap,
    this.onTap,
    this.readOnly = false,
    this.onChanged,
    this.obscureText = false,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
        onChanged: onChanged,
        onTap: onTap,
        obscureText: obscureText,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        style: TextStyle(
          color: textColor,
          fontSize: 14.sp,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: backgroundColor,
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon, 
                  color: Colors.grey.shade600,
                  size: 20.sp,
                )
              : null,
          hintText: hint,
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: 14.sp,
          ),
          suffixIcon: suffixIcon != null
              ? IconButton(
                  icon: Icon(
                    suffixIcon,
                    color: Colors.grey.shade600,
                    size: 20.sp,
                  ),
                  onPressed: onSuffixTap,
                )
              : null,
          border: _buildOutlineBorder(),
          enabledBorder: _buildOutlineBorder(),
          focusedBorder: _buildFocusedBorder(),
          errorBorder: _buildErrorBorder(),
          focusedErrorBorder: _buildErrorBorder(),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w, 
            vertical: maxLines! > 1 ? 12.h : 11.h,
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _buildOutlineBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.r),
      borderSide: BorderSide(
        color: borderColor ?? Colors.grey.shade300,
        width: 1.5,
      ),
    );
  }

  OutlineInputBorder _buildFocusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.r),
      borderSide: BorderSide(
        color: Colors.blue.shade400,
        width: 2,
      ),
    );
  }

  OutlineInputBorder _buildErrorBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.r),
      borderSide: BorderSide(
        color: Colors.red.shade400,
        width: 2,
      ),
    );
  }
}