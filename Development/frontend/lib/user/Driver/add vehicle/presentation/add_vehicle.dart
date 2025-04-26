import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../components/CustomButton.dart';
import '../../../../components/CustomTextField.dart';
import '../../../../core/constants.dart';
import '../../../authentication/login/providers/auth_provider.dart';
import 'select_seats_screen.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AddVehicle extends ConsumerStatefulWidget {
  const AddVehicle({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AddVehicleState();
}

class _AddVehicleState extends ConsumerState<AddVehicle> {
  String _selectedVehicleType = 'Taxi';
  String _userType = 'Single';
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _arrivalController = TextEditingController();
  bool _isLoading = false;

  Set<String> _selectedSeats = {};

  Future<void> addVehicle() async {
    // Form validation before sending request
    if (!_isFormValid()) {
      _showErrorMessage("Please fill all required fields and select seats");
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final authState = ref.read(authProvider).userId;
    try {
      final url = Uri.parse("$apiBaseUrl/addVehicle");

      final body = {
        "vehicleNo": _vehicleNumberController.text,
        "model": _vehicleModelController.text,
        "vehicleType": _selectedVehicleType,
        "departure": _departureController.text,
        "arrivalTime": _arrivalController.text,
        "registerAs": _userType == "Single" ? "Single" : _organizationController.text,
        "ownerId": authState,
        "seatNo": _selectedSeats.map((seat) => int.parse(seat)).toList()
      };

      print('Adding vehicle: $body');

      final response = await http.post(
        url,
        body: json.encode(body),
        headers: {
          "Content-Type": "application/json",
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Vehicle added successfully: $data');
        final vehicleId = data['vehicle']['id'].toString();

        context.pushReplacementNamed('addRoute',
            pathParameters: {'id': vehicleId});
      } else {
        print('Failed to add vehicle: ${response.body}');
        _showErrorMessage("Failed to add vehicle. Please try again.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error adding vehicle: $e');
      _showErrorMessage("An error occurred. Please check your connection.");
    }
  }

  bool _isFormValid() {
    // Check if organization name is filled when organization type is selected
    if (_userType == 'Organization' && _organizationController.text.isEmpty) {
      return false;
    }
    
    // Check if other required fields are filled
    if (_vehicleModelController.text.isEmpty ||
        _vehicleNumberController.text.isEmpty ||
        _departureController.text.isEmpty ||
        _arrivalController.text.isEmpty ||
        _selectedSeats.isEmpty) {
      return false;
    }
    
    return true;
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _navigateToSeatSelection() async {
    final selectedSeats = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectSeatsScreen(
          vehicleType: _selectedVehicleType,
          selectedSeats: _selectedSeats,
        ),
      ),
    );

    if (selectedSeats != null) {
      setState(() {
        _selectedSeats = selectedSeats;
      });
    }
  }

  // Clock time picker
  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null) {
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      
      final formattedTime = DateFormat("yyyy-MM-ddTHH:mm:ss'Z'").format(selectedDateTime);
      
      setState(() {
        controller.text = formattedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Add Vehicle',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: "Register As",
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildUserTypeButton('Single'),
                            SizedBox(width: 20.w),
                            _buildUserTypeButton('Organization'),
                          ],
                        ),
                        if (_userType == 'Organization') ...[
                          SizedBox(height: 20.h),
                          CustomTextField(
                            controller: _organizationController,
                            hint: 'Enter Organization Name',
                            prefixIcon: Icons.business,
                            backgroundColor: Colors.grey.shade50,
                            borderColor: Colors.grey.shade200,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  _buildSectionCard(
                    title: "Vehicle Type",
                    child: Row(
                      children: [
                        _buildVehicleTypeButton('Taxi'),
                        SizedBox(width: 20.w),
                        _buildVehicleTypeButton('Bus'),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  _buildSectionCard(
                    title: "Vehicle Details",
                    child: Column(
                      children: [
                        CustomTextField(
                          hint: 'Vehicle Model',
                          controller: _vehicleModelController,
                          prefixIcon: Icons.directions_car,
                          backgroundColor: Colors.grey.shade50,
                          borderColor: Colors.grey.shade200,
                        ),
                        SizedBox(height: 15.h),
                        CustomTextField(
                          hint: 'Vehicle Number',
                          controller: _vehicleNumberController,
                          prefixIcon: Icons.confirmation_number,
                          backgroundColor: Colors.grey.shade50,
                          borderColor: Colors.grey.shade200,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  _buildSectionCard(
                    title: "Timing",
                    child: Column(
                      children: [
                        _buildTimePickerField(
                          controller: _departureController,
                          label: "Departure Time",
                          icon: Icons.access_time,
                        ),
                        SizedBox(height: 15.h),
                        _buildTimePickerField(
                          controller: _arrivalController,
                          label: "Arrival Time",
                          icon: Icons.alarm,
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  _buildSectionCard(
                    title: "Select Seats",
                    child: Column(
                      children: [
                        CustomButton(
                          text: _selectedSeats.isEmpty
                              ? "Select Seats of Vehicle"
                              : "Seats Selected (${_selectedSeats.length})",
                          width: double.infinity,
                          onPressed: _navigateToSeatSelection,
                          color: _selectedSeats.isEmpty
                              ? Colors.grey.shade300
                              : Colors.green.shade400,
                          boxShadow: _selectedSeats.isEmpty
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.green.shade200,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  )
                                ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 30.h),
                  
                  CustomButton(
                    text: "Submit Vehicle",
                    width: double.infinity,
                    onPressed: addVehicle,
                    color: Colors.green.shade600,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade200,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                    height: 50.h,
                    fontSize: 16.sp,
                  ),
                  
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "Adding Vehicle...",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Divider(height: 24.h),
          child,
        ],
      ),
    );
  }

  Widget _buildVehicleTypeButton(String type) {
    return Expanded(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _selectedVehicleType == type 
              ? Colors.green.shade400 
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          boxShadow: _selectedVehicleType == type
              ? [
                  BoxShadow(
                    color: Colors.green.shade200,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                _selectedVehicleType = type;
                _selectedSeats.clear();
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type == 'Taxi' ? Icons.local_taxi : Icons.directions_bus,
                    color: _selectedVehicleType == type 
                        ? Colors.white 
                        : Colors.black87,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    type,
                    style: TextStyle(
                      color: _selectedVehicleType == type 
                          ? Colors.white 
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeButton(String type) {
    return Expanded(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _userType == type 
              ? Colors.orange.shade400 
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          boxShadow: _userType == type
              ? [
                  BoxShadow(
                    color: Colors.orange.shade200,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                _userType = type;
              });
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type == 'Single' ? Icons.person : Icons.business,
                    color: _userType == type 
                        ? Colors.white 
                        : Colors.black87,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    type,
                    style: TextStyle(
                      color: _userType == type 
                          ? Colors.white 
                          : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTimePickerField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    // Format time for display if set
    String displayText = 'Select Time';
    if (controller.text.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(controller.text);
        displayText = DateFormat('h:mm a').format(dateTime);
      } catch (e) {
        displayText = controller.text;
      }
    }
    
    return InkWell(
      onTap: () => _selectTime(controller),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey.shade700,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              displayText,
              style: TextStyle(
                color: controller.text.isEmpty ? 
                    Colors.grey.shade500 : 
                    Colors.black87,
                fontSize: 14.sp,
              ),
            ),
            Spacer(),
            if (controller.text.isNotEmpty)
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.green.shade700,
                  size: 12.sp,
                ),
              ),
          ],
        ),
      ),
    );
  }
}