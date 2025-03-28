import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/components/CustomButton.dart';
import 'package:frontend/core/constants.dart';
import 'package:frontend/user/map/providers/map_provider.dart';
import 'package:frontend/user/authentication/login/providers/auth_provider.dart';
import 'package:frontend/user/Passenger/bus%20details/providers/bus_details_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../../../components/AppColors.dart';
import '../../bus list/providers/bus_list_provider.dart';
import 'select_seat_screen.dart';

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
  bool isSearching = true;
  Timer? _debounce;
  Set<String> _bookedSeats = {};

  List<String> _pickupSuggestions = [];
  List<String> _dropoffSuggestions = [];
  bool _showPickupSuggestions = false;
  bool _showDropoffSuggestions = false;

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
    _debounce?.cancel();
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
          bookedSeats: _bookedSeats,
        ),
      ),
    );

    if (selectedSeats != null) {
      setState(() {
        _selectedSeats = selectedSeats;
      });
    }
  }

  Future<void> getBookedSeats() async {
    try {
      final vehicleId = widget.busId;
      final dateTime = _dateTimeController.text;

      if (dateTime.isEmpty) {
        print("No date selected.");
        return;
      }

      final formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'")
          .format(DateFormat("yyyy-MM-dd HH:mm").parse(dateTime));

      final response = await http.get(
        Uri.parse(
            "$apiBaseUrl/getBookingByDate?date=$formattedDate&vehicleId=$vehicleId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final bookedSeats = data
            .expand((booking) => booking["bookingSeats"])
            .map((seat) => seat["seatNo"].toString())
            .toSet();
        print("Booked Seats: $bookedSeats");

        setState(() {
          _bookedSeats = bookedSeats; // Update UI with booked seats
        });

        print("Booked Seats: $_bookedSeats");
      } else {
        print("Failed to fetch booked seats: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching booked seats: $e");
    }
  }

  /// **Handles location search and updates the suggestion list**
  void _debouncedSearch(String query, MapNotifier mapNotifier, bool isPickup) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isNotEmpty) {
        await mapNotifier.searchPlaces(query);
        final searchResults = ref.read(mapProvider).searchResults;

        setState(() {
          if (isPickup) {
            _pickupSuggestions = searchResults
                .map((location) => location.address ?? "")
                .toList();
            _showPickupSuggestions = true;
          } else {
            _dropoffSuggestions = searchResults
                .map((location) => location.address ?? "")
                .toList();
            _showDropoffSuggestions = true;
          }
        });
      } else {
        setState(() {
          if (isPickup) {
            _pickupSuggestions.clear();
            _showPickupSuggestions = false;
          } else {
            _dropoffSuggestions.clear();
            _showDropoffSuggestions = false;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapNotifier = ref.read(mapProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Book Seat",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchField(
                controller: _pickupController,
                hint: "From Location",
                onSearch: (query) => _debouncedSearch(query, mapNotifier, true),
              ),
              _showPickupSuggestions
                  ? _buildSuggestions(_pickupSuggestions, true)
                  : const SizedBox(),
              SizedBox(height: 16.h),
              _buildSearchField(
                controller: _dropoffController,
                hint: "To Location",
                onSearch: (query) =>
                    _debouncedSearch(query, mapNotifier, false),
              ),
              _showDropoffSuggestions
                  ? _buildSuggestions(_dropoffSuggestions, false)
                  : const SizedBox(),
              SizedBox(height: 16.h),
              _buildLabel("Date and Time"),
              GestureDetector(
                onTap: _selectDateTime,
                child: AbsorbPointer(
                  child: TextField(
                    controller: _dateTimeController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Select date and time',
                      suffixIcon: const Icon(Icons.calendar_today,
                          color: AppColors.iconColor),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              CustomButton(
                text: _selectedSeats.isEmpty
                    ? "Select Seats"
                    : "Seats Selected (${_selectedSeats.length})",
                width: double.infinity,
                onPressed: _navigateToSeatSelection,
                color: _selectedSeats.isEmpty
                    ? AppColors.secondary
                    : AppColors.buttonColor,
              ),
              SizedBox(height: 30.h),
              Center(
                child: ElevatedButton(
                  onPressed: _bookSeat,
                  style: ElevatedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 40.w, vertical: 15.h),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r)),
                  ),
                  child: Text("Confirm Booking",
                      style: TextStyle(
                          color: AppColors.buttonText, fontSize: 16.sp)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required Function(String) onSearch,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: BorderSide.none),
        prefixIcon: const Icon(Icons.search, color: AppColors.iconColor),
      ),
      onChanged: onSearch,
    );
  }

  Widget _buildSuggestions(List<String> suggestions, bool isPickup) {
    return Container(
      height: 150.h,
      margin: EdgeInsets.symmetric(vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(suggestions[index],
                style: const TextStyle(color: AppColors.textPrimary)),
            onTap: () {
              setState(() {
                if (isPickup) {
                  _pickupController.text = suggestions[index];
                  _showPickupSuggestions = false;
                } else {
                  _dropoffController.text = suggestions[index];
                  _showDropoffSuggestions = false;
                }
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.h),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary),
      ),
    );
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
        getBookedSeats();
      }
    }
  }
}
