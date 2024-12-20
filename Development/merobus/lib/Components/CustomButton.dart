import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double? height;
  final double? fontSize;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Color? borderColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.width,
    this.height,
    this.fontSize,
    this.borderRadius,
    this.boxShadow,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(borderRadius ?? 8.r),
          border: Border.all(color: borderColor ?? Colors.transparent),
          boxShadow: boxShadow ??
              [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 0),
                ),
              ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent, // Disable default shadow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 8.r),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize ?? 16.sp,
              color: textColor ?? Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}