import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:frontend/components/AppColors.dart';
import 'package:frontend/components/CustomButton.dart';
import 'package:frontend/components/CustomTextField.dart';

class RoleChangeScreen extends ConsumerStatefulWidget {
  const RoleChangeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RoleChangeScreenState();
}

class _RoleChangeScreenState extends ConsumerState<RoleChangeScreen> {
  File? _selectedFile;
  String? _fileName;
  String? _errorMessage;
  final String _selectedVehicle = "Bus"; // Default selected vehicle
  final int maxFileSize = 250 * 1024; // 250KB in bytes
  final TextEditingController _licenseController = TextEditingController();

  /// Picks a file from device storage
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any, // Allow all file types
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      if (file.lengthSync() > maxFileSize) {
        setState(() {
          _errorMessage = "File size exceeds 250KB!";
          _selectedFile = null;
          _fileName = null;
        });
      } else {
        setState(() {
          _selectedFile = file;
          _fileName = fileName;
          _errorMessage = null;
        });
      }
    }
  }

  /// **Checks if the selected file is an image**
  bool _isImageFile(String filePath) {
    return filePath.toLowerCase().endsWith('.png') ||
        filePath.toLowerCase().endsWith('.jpg') ||
        filePath.toLowerCase().endsWith('.jpeg') ||
        filePath.toLowerCase().endsWith('.gif');
  }

  /// **Handle Form Submission**
  void _handleSubmit() {
    setState(() {
      _errorMessage = null;
    });

    if (_licenseController.text.isEmpty) {
      setState(() {
        _errorMessage = "License number is required!";
      });
      return;
    }

    if (_selectedFile == null) {
      setState(() {
        _errorMessage = "Please upload your license image!";
      });
      return;
    }

    // **TODO: Submit data to backend or next step**
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Application Submitted Successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Be a Driver'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "License Number",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),
              CustomTextField(
                controller: _licenseController,
                hint: "Enter License Number",
                backgroundColor: Color(0xFFF1F1F1),
                borderColor: Colors.transparent,
              ),
              SizedBox(height: 20.h),

              SizedBox(height: 20.h),

              Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    "License Image",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  )),

              /// **GestureDetector now displays the selected file**
              GestureDetector(
                onTap: _pickFile,
                child: DottedBorder(
                  color: Colors.black,
                  strokeWidth: 1.w,
                  borderType: BorderType.RRect,
                  radius: Radius.circular(9.r),
                  dashPattern: [6, 3],
                  child: Container(
                    height: 165.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Color(0xFFF5FFE7),
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    child: _selectedFile != null
                        ? _isImageFile(_selectedFile!.path)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(9.r),
                                child: Image.file(
                                  _selectedFile!,
                                  width: double.infinity,
                                  height: 165.h,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.insert_drive_file,
                                      size: 40.h, color: Colors.black54),
                                  SizedBox(height: 10.h),
                                  Text(
                                    "Selected: $_fileName",
                                    style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  SizedBox(height: 5.h),
                                  Text(
                                    "Tap to change file",
                                    style: TextStyle(
                                        color: Colors.black54, fontSize: 12.sp),
                                  ),
                                ],
                              )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.file_upload_outlined,
                                  size: 40.h, color: Colors.black54),
                              SizedBox(height: 10.h),
                              Text.rich(
                                TextSpan(
                                  text: "Choose ",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700),
                                  children: [
                                    TextSpan(
                                      text: "file to upload",
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 5.h),
                              Text(
                                "File size must be 250KB",
                                style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12.sp),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              if (_errorMessage != null) // Display error message
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 12.sp),
                  ),
                ),

              SizedBox(height: 30.h),

              /// **Submit & Cancel Buttons**
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomButton(
                    text: "Cancel",
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    width: 165.w,
                    textColor: Colors.black,
                    color: Color(0xFFF1F1F1),
                  ),
                  CustomButton(
                    text: "Submit",
                    onPressed: _handleSubmit,
                    width: 165.w,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
