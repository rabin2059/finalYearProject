import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/components/CustomTextField.dart';
import 'package:frontend/components/CustomButton.dart'; // Import CustomButton
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
  String _selectedVehicleType = 'Taxi'; // Default type
  String _userType = 'Single'; // Default user type
  final TextEditingController _organizationController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehicleNumberController =
      TextEditingController();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _arrivalController = TextEditingController();

  Set<String> _selectedSeats = {}; // Store selected seats

  @override
  void initState() {
    super.initState();
  }

  Future<void> addVehicle() async {
    final authState =
        ref.read(authProvider).userId; // ✅ Use `read` instead of `watch`
    try {
      final url = Uri.parse("$apiBaseUrl/addVehicle");

      final body = {
        "vehicleNo": _vehicleNumberController.text,
        "model": _vehicleModelController.text,
        "vehicleType": _selectedVehicleType,
        "departure": _departureController.text,
        "arrivalTime": _arrivalController.text,
        "registerAs":
            _userType == "Single" ? "Single" : _organizationController.text,
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
        final data = json.decode(response.body); // ✅ Decode response JSON
        print('Vehicle added successfully: $data');
        final vehicleId =
            data['vehicle']['id'].toString(); // ✅ Convert int to string

        context.pushReplacementNamed('addRoute',
            pathParameters: {'id': vehicleId});
      } else {
        print('Failed to add vehicle: ${response.body}');
      }
    } catch (e) {
      print('Error adding vehicle: $e');
    }
  }

  /// **Navigates to SelectSeatsScreen**
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
      appBar: AppBar(
        title: Text('Add Vehicle'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Register As:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _buildUserTypeButton('Single'),
                  SizedBox(width: 20.w),
                  _buildUserTypeButton('Organization'),
                ],
              ),
              SizedBox(height: 10.h),
              if (_userType == 'Organization')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Organization Name",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    CustomTextField(
                      controller: _organizationController,
                      hint: 'Enter Organization Name',
                    ),
                    SizedBox(height: 10.h),
                  ],
                ),
              Text("Vehicle Type",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _buildVehicleTypeButton('Taxi'),
                  SizedBox(width: 20.w),
                  _buildVehicleTypeButton('Bus'),
                ],
              ),
              SizedBox(height: 10.h),
              Text("Vehicle Model",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              CustomTextField(
                hint: 'Model',
                controller: _vehicleModelController,
              ),
              SizedBox(height: 10.h),
              Text("Vehicle No.",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              CustomTextField(
                hint: 'Vehicle No.',
                controller: _vehicleNumberController,
              ),
              SizedBox(height: 20.h),
              Text("Departure Time",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              CustomTextField(
                hint: 'Departure Time',
                controller: _departureController,
              ),
              SizedBox(height: 20.h),
              Text("Arrival Time",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              CustomTextField(
                hint: 'Arrival Time',
                controller: _arrivalController,
              ),
              SizedBox(height: 20.h),

              // **Select Seats Button**
              Center(
                child: CustomButton(
                  text: _selectedSeats.isEmpty
                      ? "Select Seats of Vehicle"
                      : "Seats Selected",
                  width: 300.w,
                  onPressed: _navigateToSeatSelection,
                  color: _selectedSeats.isEmpty
                      ? Colors.grey
                      : Colors.blue, // Dynamic color
                ),
              ),

              SizedBox(height: 20.h),

              CustomButton(
                text: "Submit",
                // width: 200.w,
                onPressed: () {
                  addVehicle();
                },
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// **Builds Vehicle Type Selection Buttons (Taxi or Bus)**
  Widget _buildVehicleTypeButton(String type) {
    return Expanded(
      child: CustomButton(
        text: type,
        onPressed: () {
          setState(() {
            _selectedVehicleType = type;
            _selectedSeats
                .clear(); // Reset selected seats when changing vehicle type
          });
        },
        color: _selectedVehicleType == type ? Colors.green : Colors.grey[300],
        textColor: _selectedVehicleType == type ? Colors.white : Colors.black,
      ),
    );
  }

  /// **Builds User Type Selection Buttons (Single or Organization)**
  Widget _buildUserTypeButton(String type) {
    return Expanded(
      child: CustomButton(
        text: type,
        onPressed: () {
          setState(() {
            _userType = type;
          });
        },
        color: _userType == type ? Colors.orange : Colors.grey[300],
        textColor: _userType == type ? Colors.white : Colors.black,
      ),
    );
  }
}
