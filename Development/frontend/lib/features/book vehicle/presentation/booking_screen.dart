import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/components/CustomButton.dart';
import 'package:frontend/components/CustomTextField.dart';
import 'package:frontend/features/bus%20details/providers/bus_details_provider.dart';
import 'package:intl/intl.dart';
import 'select_seat_screen.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  Set<String> _selectedSeats = {}; // Store selected seats

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
                  // Handle booking logic
                  print("Booking Confirmed");
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
