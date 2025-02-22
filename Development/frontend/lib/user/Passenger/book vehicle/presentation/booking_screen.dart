import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/components/CustomButton.dart';
import 'package:frontend/components/CustomTextField.dart';
import 'package:frontend/core/constants.dart';
import 'package:frontend/user/authentication/login/providers/auth_provider.dart';
import 'package:frontend/user/Passenger/bus%20details/providers/bus_details_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../bus list/providers/bus_list_provider.dart';
import 'select_seat_screen.dart';
import 'package:http/http.dart' as http;

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.busId});
  final int busId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  Set<String> _selectedSeats = {}; // Store selected seats

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _dateTimeController.dispose();
    _selectedSeats.clear();
    super.dispose();
  }

  Future<void> _bookSeat() async {
    try {
      final authState = ref.watch(authProvider);
      final state = ref.watch(busDetailsProvider);
      final userId = authState.userId;
      print(userId);
      final url = apiBaseUrl;
      final formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(
        DateFormat("yyyy-MM-dd HH:mm").parse(_dateTimeController.text),
      );
      final body = {
        "userId": userId,
        "vehicleId": widget.busId,
        "bookingDate": formattedDate,
        "pickUpPoint": _pickupController.text,
        "dropOffPoint": _dropoffController.text,
        "totalFare": (state.vehicle?.route?.isNotEmpty ?? false)
            ? (state.vehicle!.route![0].fare! * _selectedSeats.length)
            : 0,
        "seatNo": _selectedSeats.toList()
      };


      final response = await http.post(
        Uri.parse("$url/booking"),
        body: json.encode(body),
        headers: {
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final success = data["success"];
        if (success) {
          setState(() {
            _pickupController.clear();
            _dropoffController.clear();
            _dateTimeController.clear();
            _selectedSeats.clear();
          });
          ref.read(busProvider.notifier).fetchBusList(); // Refresh bus list
          ref
              .read(busDetailsProvider.notifier)
              .fetchBusDetail(widget.busId); // Refresh bus list
          final bookingId = data["result"]["newBooking"]["id"];
          context.pushReplacementNamed('/overview',
              pathParameters: {'id': bookingId.toString()});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"])),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book seat')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book seat: $e')),
      );
    }
  }

  /// **Navigates to SelectSeatsScreen**
  Future<void> _navigateToSeatSelection() async {
    final state = ref.watch(busDetailsProvider);
    final selectedSeats = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectSeatScreen(
          vehicleType: state.vehicle?.vehicleType ?? "Unknown",
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

  /// **Handles Date & Time Selection**
  Future<void> _selectDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _dateTimeController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(fullDateTime);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Seat"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Pick Up From"),
            CustomTextField(
              controller: _pickupController,
              hint: 'Enter pickup address',
            ),
            SizedBox(height: 16.h),
            _buildLabel("Drop Off To"),
            CustomTextField(
                controller: _dropoffController, hint: 'Enter drop-off address'),
            SizedBox(height: 16.h),
            _buildLabel("Date and Time"),
            GestureDetector(
              onTap: _selectDateTime,
              child: AbsorbPointer(
                child: TextField(
                  controller: _dateTimeController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select date and time',
                    suffixIcon:
                        const Icon(Icons.calendar_today, color: Colors.grey),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 10.h,
            ),
            CustomButton(
              text: _selectedSeats.isEmpty ? "Select Seats" : "Seats Selected",
              width: 200.w,
              onPressed: _navigateToSeatSelection,
              color: _selectedSeats.isEmpty
                  ? Colors.grey
                  : Colors.blue, // Dynamic color
            ),
            SizedBox(height: 30.h),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _bookSeat();
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 40.w, vertical: 15.h),
                  backgroundColor: Colors.green,
                ),
                child: Text("Confirm Booking",
                    style: TextStyle(color: Colors.white, fontSize: 16.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **Reusable Label Widget**
  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.h),
      child: Text(
        text,
        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}
