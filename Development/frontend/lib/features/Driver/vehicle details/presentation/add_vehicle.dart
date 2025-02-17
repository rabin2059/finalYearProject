import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/components/CustomTextField.dart';
import 'package:frontend/components/CustomButton.dart'; // Import CustomButton
import 'select_seats_screen.dart';

class AddVehicle extends ConsumerStatefulWidget {
  const AddVehicle({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AddVehicleState();
}

class _AddVehicleState extends ConsumerState<AddVehicle> {
  String _selectedVehicleType = 'Taxi'; // Default type
  String _userType = 'Single'; // Default user type
  final TextEditingController _organizationController = TextEditingController();
  Set<String> _selectedSeats = {}; // Store selected seats

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
              CustomTextField(hint: 'Model'),
              SizedBox(height: 10.h),
              Text("Vehicle No.",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              CustomTextField(hint: 'Vehicle No.'),
              SizedBox(height: 20.h),

              // **Select Seats Button**
              CustomButton(
                text:
                    _selectedSeats.isEmpty ? "Select Seats" : "Seats Selected",
                width: 200.w,
                onPressed: _navigateToSeatSelection,
                color: _selectedSeats.isEmpty
                    ? Colors.grey
                    : Colors.blue, // Dynamic color
              ),

              SizedBox(height: 20.h),

              Center(
                child: CustomButton(
                  text: "Submit",
                  width: 200.w,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              "Vehicle Registered! Seats Selected: ${_selectedSeats.length}")),
                    );
                  },
                  color: Colors.green,
                ),
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
