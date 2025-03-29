import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/components/CustomTextField.dart';
import 'package:frontend/components/CustomButton.dart';
import 'package:frontend/core/constants.dart';
import 'package:frontend/user/authentication/login/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'select_seats_screen.dart';
import 'package:http/http.dart' as http;

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

  Set<String> _selectedSeats = {};

  Future<void> addVehicle() async {
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Vehicle added successfully: $data');
        final vehicleId = data['vehicle']['id'].toString();

        context.pushReplacementNamed('addRoute',
            pathParameters: {'id': vehicleId});
      } else {
        print('Failed to add vehicle: ${response.body}');
      }
    } catch (e) {
      print('Error adding vehicle: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Add Vehicle',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Register As"),
              SizedBox(height: 10.h),
              Row(
                children: [
                  _buildUserTypeButton('Single'),
                  SizedBox(width: 20.w),
                  _buildUserTypeButton('Organization'),
                ],
              ),
              if (_userType == 'Organization') ...[
                SizedBox(height: 15.h),
                _buildSectionTitle("Organization Name"),
                CustomTextField(
                  controller: _organizationController,
                  hint: 'Enter Organization Name',
                  prefixIcon: Icons.business,
                ),
              ],
              SizedBox(height: 15.h),
              _buildSectionTitle("Vehicle Type"),
              SizedBox(height: 10.h),
              Row(
                children: [
                  _buildVehicleTypeButton('Taxi'),
                  SizedBox(width: 20.w),
                  _buildVehicleTypeButton('Bus'),
                ],
              ),
              SizedBox(height: 15.h),
              _buildSectionTitle("Vehicle Details"),
              SizedBox(height: 10.h),
              CustomTextField(
                hint: 'Vehicle Model',
                controller: _vehicleModelController,
                prefixIcon: Icons.directions_car,
              ),
              SizedBox(height: 15.h),
              CustomTextField(
                hint: 'Vehicle Number',
                controller: _vehicleNumberController,
                prefixIcon: Icons.numbers,
              ),
              SizedBox(height: 15.h),
              _buildSectionTitle("Timing"),
              SizedBox(height: 10.h),
              CustomTextField(
                hint: 'Departure Time',
                controller: _departureController,
                prefixIcon: Icons.access_time,
              ),
              SizedBox(height: 15.h),
              CustomTextField(
                hint: 'Arrival Time',
                controller: _arrivalController,
                prefixIcon: Icons.alarm,
              ),
              SizedBox(height: 20.h),
              Center(
                child: CustomButton(
                  text: _selectedSeats.isEmpty
                      ? "Select Seats of Vehicle"
                      : "Seats Selected (${_selectedSeats.length})",
                  width: 300.w,
                  onPressed: _navigateToSeatSelection,
                  color: _selectedSeats.isEmpty
                      ? Colors.grey.shade300
                      : Colors.green.shade400,
                ),
              ),
              SizedBox(height: 20.h),
              Center(
                child: CustomButton(
                  text: "Submit Vehicle",
                  width: 300.w,
                  onPressed: addVehicle,
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
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
              child: Center(
                child: Text(
                  type,
                  style: TextStyle(
                    color: _selectedVehicleType == type 
                        ? Colors.white 
                        : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
              child: Center(
                child: Text(
                  type,
                  style: TextStyle(
                    color: _userType == type 
                        ? Colors.white 
                        : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}