import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../../../components/AppColors.dart';
import '../../../../core/constants.dart';
import '../../../authentication/login/providers/auth_provider.dart';
import '../../../map/providers/map_provider.dart';
import '../../bus details/providers/bus_details_provider.dart';
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
  bool _isLoading = false;

  List<String> _pickupSuggestions = [];
  List<String> _dropoffSuggestions = [];
  bool _showPickupSuggestions = false;
  bool _showDropoffSuggestions = false;

  // Focus nodes for text fields
  final FocusNode _pickupFocusNode = FocusNode();
  final FocusNode _dropoffFocusNode = FocusNode();

  // Animation controllers
  late AnimationController _animationController;
  bool _isBookingFormValid = false;

  @override
  void initState() {
    super.initState();

    // Add listeners to update validation status
    _pickupController.addListener(_validateForm);
    _dropoffController.addListener(_validateForm);
    _dateTimeController.addListener(_validateForm);

    // Get vehicle details initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(busDetailsProvider.notifier).fetchBusDetail(widget.busId);
    });
  }

  void _validateForm() {
    setState(() {
      _isBookingFormValid = _pickupController.text.isNotEmpty &&
          _dropoffController.text.isNotEmpty &&
          _dateTimeController.text.isNotEmpty &&
          _selectedSeats.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _dateTimeController.dispose();
    _selectedSeats.clear();
    _debounce?.cancel();
    _pickupFocusNode.dispose();
    _dropoffFocusNode.dispose();
    super.dispose();
  }

  Future<void> _bookSeat() async {
    if (!_isBookingFormValid) {
      _showErrorMessage("Please fill all fields and select seats.");
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final authState = ref.watch(authProvider);
      final state = ref.watch(busDetailsProvider);
      final userId = authState.userId;

      if (userId == null) {
        _showErrorMessage("You need to be logged in to book a seat.");
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final url = apiBaseUrl;
      final formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(
        DateFormat("yyyy-MM-dd HH:mm").parse(_dateTimeController.text),
      );

      final fare = (state.vehicle?.route?.isNotEmpty ?? false)
          ? (state.vehicle!.route![0].fare! * _selectedSeats.length)
          : 0;

      final body = {
        "userId": userId,
        "vehicleId": widget.busId,
        "bookingDate": formattedDate,
        "pickUpPoint": _pickupController.text,
        "dropOffPoint": _dropoffController.text,
        "totalFare": fare,
        "seatNo": _selectedSeats.toList()
      };

      final response = await http.post(
        Uri.parse("$url/booking"),
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
        final success = data["success"];
        if (success) {
          setState(() {
            _pickupController.clear();
            _dropoffController.clear();
            _dateTimeController.clear();
            _selectedSeats.clear();
          });

          ref.read(busProvider.notifier).fetchBusList(); // Refresh bus list
          ref.read(busDetailsProvider.notifier).fetchBusDetail(widget.busId);

          final bookingId = data["result"]["newBooking"]["id"];

          _showSuccessMessage("Booking Successful!");

          Future.delayed(const Duration(milliseconds: 1500), () {
            context.pushReplacementNamed('/overview',
                pathParameters: {'id': bookingId.toString()});
          });
        } else {
          _showErrorMessage(
              data["message"] ?? "Booking failed. Please try again.");
        }
      } else {
        _showErrorMessage('Booking failed. Please try again later.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage('An error occurred: ${e.toString().split('\n')[0]}');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10.w),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10.w),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _navigateToSeatSelection() async {
    final state = ref.watch(busDetailsProvider);

    if (_dateTimeController.text.isEmpty) {
      _showErrorMessage("Please select a date and time first.");
      return;
    }

    // Show loading indicator while fetching booked seats
    setState(() {
      _isLoading = true;
    });

    await getBookedSeats();

    setState(() {
      _isLoading = false;
    });

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
      _validateForm();
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

        setState(() {
          _bookedSeats = bookedSeats;
        });
      } else {
        _showErrorMessage("Failed to fetch booked seats. Please try again.");
      }
    } catch (e) {
      _showErrorMessage("Could not check seat availability.");
    }
  }

  void _debouncedSearch(String query, MapNotifier mapNotifier, bool isPickup) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isNotEmpty) {
        setState(() {
          isSearching = true;
        });

        await mapNotifier.searchPlaces(query);
        final searchResults = ref.read(mapProvider).searchResults;

        setState(() {
          isSearching = false;
          if (isPickup) {
            _pickupSuggestions = searchResults
                .map((location) => location.address ?? "")
                .toList();
            _showPickupSuggestions = _pickupSuggestions.isNotEmpty;
          } else {
            _dropoffSuggestions = searchResults
                .map((location) => location.address ?? "")
                .toList();
            _showDropoffSuggestions = _dropoffSuggestions.isNotEmpty;
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
    final busDetails = ref.watch(busDetailsProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final fare = (busDetails.vehicle?.route?.isNotEmpty ?? false)
        ? busDetails.vehicle!.route![0].fare! * _selectedSeats.length
        : 0;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          _showPickupSuggestions = false;
          _showDropoffSuggestions = false;
        });
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppColors.textPrimary,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            "Book Your Seat",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          actions: [
          ],
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // Custom background
            Container(
              height: 100.h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.r),
                  bottomRight: Radius.circular(30.r),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Booking Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your Trip Details",
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 20.h),

                            _buildSearchFieldWithIcon(
                              controller: _pickupController,
                              hint: "Enter pickup location",
                              icon: Icons.location_on,
                              iconColor: Colors.green,
                              focusNode: _pickupFocusNode,
                              onSearch: (query) =>
                                  _debouncedSearch(query, mapNotifier, true),
                            ),

                            if (_showPickupSuggestions)
                              isSearching
                                  ? _buildLoadingIndicator()
                                  : _buildSuggestions(_pickupSuggestions, true),

                            SizedBox(height: 16.h),

                            _buildSearchFieldWithIcon(
                              controller: _dropoffController,
                              hint: "Enter drop-off location",
                              icon: Icons.location_off,
                              iconColor: Colors.red,
                              focusNode: _dropoffFocusNode,
                              onSearch: (query) =>
                                  _debouncedSearch(query, mapNotifier, false),
                            ),

                            if (_showDropoffSuggestions)
                              isSearching
                                  ? _buildLoadingIndicator()
                                  : _buildSuggestions(
                                      _dropoffSuggestions, false),

                            SizedBox(height: 20.h),

                            Text(
                              "When do you want to travel?",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 10.h),

                            GestureDetector(
                              onTap: _selectDateTime,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(15.r),
                                  border: Border.all(
                                    color: _dateTimeController.text.isEmpty
                                        ? Colors.grey.shade300
                                        : AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 12.h),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: _dateTimeController.text.isEmpty
                                          ? AppColors.iconColor
                                          : AppColors.primary,
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Text(
                                        _dateTimeController.text.isEmpty
                                            ? 'Select date and time'
                                            : _formatDateTime(
                                                _dateTimeController.text),
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          color:
                                              _dateTimeController.text.isEmpty
                                                  ? Colors.grey.shade600
                                                  : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (_dateTimeController.text.isNotEmpty)
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20.sp,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Seat Selection Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Seat Selection",
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 15.h),

                            // Seat selection button
                            ElevatedButton.icon(
                              onPressed: _navigateToSeatSelection,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: 15.h,
                                  horizontal: 20.w,
                                ),
                                backgroundColor: _selectedSeats.isEmpty
                                    ? Colors.grey.shade100
                                    : Colors.blue.shade50,
                                foregroundColor: _selectedSeats.isEmpty
                                    ? Colors.black87
                                    : AppColors.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.r),
                                  side: BorderSide(
                                    color: _selectedSeats.isEmpty
                                        ? Colors.grey.shade300
                                        : AppColors.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              icon: Icon(
                                _selectedSeats.isEmpty
                                    ? Icons.event_seat
                                    : Icons.check_circle,
                                size: 24.sp,
                              ),
                              label: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  _selectedSeats.isEmpty
                                      ? "Tap to Select Seats"
                                      : "${_selectedSeats.length} ${_selectedSeats.length == 1 ? 'Seat' : 'Seats'} Selected",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            if (_selectedSeats.isNotEmpty) ...[
                              SizedBox(height: 15.h),

                              // Selected seat chips
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 8.h,
                                children: _selectedSeats.map((seat) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12.w, vertical: 8.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15.r),
                                      border: Border.all(
                                        color:
                                            AppColors.primary.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      "Seat $seat",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),


                      SizedBox(height: 30.h),

                      // Confirm Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isBookingFormValid ? _bookSeat : null,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: AppColors.primary.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade600,
                          ),
                          child: Text(
                            "Confirm Booking",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: _isBookingFormValid
                                  ? AppColors.buttonText
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),

            // Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                        SizedBox(height: 15.h),
                        Text(
                          "Processing...",
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
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      margin: EdgeInsets.only(top: 5.h),
      padding: EdgeInsets.all(10.w),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          strokeWidth: 2.0,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18.sp : 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFieldWithIcon({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required FocusNode focusNode,
    required Function(String) onSearch,
  }) {
    final bool hasText = controller.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(
          color: focusNode.hasFocus || hasText
              ? AppColors.primary.withOpacity(0.8)
              : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 18.sp,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 15.sp,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              onChanged: onSearch,
              style: TextStyle(
                fontSize: 15.sp,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (hasText)
            IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.grey.shade600,
                size: 18.sp,
              ),
              onPressed: () {
                controller.clear();
                onSearch("");
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(List<String> suggestions, bool isPickup) {
    return Container(
      constraints: BoxConstraints(maxHeight: 200.h),
      margin: EdgeInsets.only(top: 5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.shade200,
          indent: 15.w,
          endIndent: 15.w,
        ),
        itemBuilder: (context, index) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isPickup) {
                    _pickupController.text = suggestions[index];
                    _showPickupSuggestions = false;
                    _dropoffFocusNode.requestFocus();
                  } else {
                    _dropoffController.text = suggestions[index];
                    _showDropoffSuggestions = false;
                    FocusScope.of(context).unfocus();
                  }
                });
                _validateForm();
              },
              borderRadius: BorderRadius.circular(15.r),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    Icon(
                      isPickup ? Icons.location_on : Icons.location_off,
                      color: isPickup ? Colors.green : Colors.red,
                      size: 16.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        suggestions[index],
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Format date time in a user-friendly format
  String _formatDateTime(String dateTimeString) {
    final dateTime = DateFormat("yyyy-MM-dd").parse(dateTimeString);
    return DateFormat("EEE, MMM d, yyyy").format(dateTime);
  }

  // Show bus details in a modal bottom sheet
  void _showBusInfo(BuildContext context, dynamic busDetails) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.r),
            topRight: Radius.circular(25.r),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      size: 30.sp,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          busDetails.vehicle?.name ?? "Bus Details",
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          "ID: ${widget.busId}",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: Colors.grey.shade200),

            Expanded(
              child: busDetails.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : busDetails.error != null
                      ? Center(
                          child: Text(
                            "Could not load bus details",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 16.sp,
                            ),
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.all(20.w),
                          child: ListView(
                            children: [
                              _buildBusInfoItem(
                                icon: Icons.directions_bus,
                                title: "Vehicle Type",
                                value: busDetails.vehicle?.vehicleType ?? "N/A",
                                color: AppColors.primary,
                              ),
                              SizedBox(height: 15.h),
                              _buildBusInfoItem(
                                icon: Icons.event_seat,
                                title: "Total Seats",
                                value: "${busDetails.vehicle?.seats ?? "N/A"}",
                                color: Colors.blue,
                              ),
                              if (busDetails.vehicle?.route?.isNotEmpty ??
                                  false) ...[
                                SizedBox(height: 15.h),
                                _buildBusInfoItem(
                                  icon: Icons.route,
                                  title: "Route",
                                  value:
                                      "${busDetails.vehicle?.route?[0].startPoint ?? ""} to ${busDetails.vehicle?.route?[0].endPoint ?? ""}",
                                  color: Colors.green,
                                ),
                                SizedBox(height: 15.h),
                                _buildBusInfoItem(
                                  icon: Icons.attach_money,
                                  title: "Fare",
                                  value:
                                      "रु ${busDetails.vehicle?.route?[0].fare ?? "N/A"}",
                                  color: Colors.amber.shade800,
                                ),
                              ],
                              SizedBox(height: 15.h),
                              _buildBusInfoItem(
                                icon: Icons.access_time,
                                title: "Average Trip Duration",
                                value:
                                    "${busDetails.vehicle?.tripDuration ?? "N/A"} minutes",
                                color: Colors.purple,
                              ),
                              if (busDetails.vehicle?.amenities?.isNotEmpty ??
                                  false) ...[
                                SizedBox(height: 25.h),
                                Text(
                                  "Amenities",
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 15.h),
                                Wrap(
                                  spacing: 10.w,
                                  runSpacing: 10.h,
                                  children: (busDetails.vehicle?.amenities
                                              as List<dynamic>? ??
                                          [])
                                      .map<Widget>((amenity) =>
                                          _buildAmenityChip(amenity))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
            ),

            Padding(
              padding: EdgeInsets.all(20.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                  ),
                  child: Text(
                    "Close",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenityChip(String amenity) {
    IconData icon;
    Color color;

    switch (amenity.toLowerCase()) {
      case 'wifi':
        icon = Icons.wifi;
        color = Colors.blue;
        break;
      case 'ac':
      case 'air conditioning':
        icon = Icons.ac_unit;
        color = Colors.cyan;
        break;
      case 'charging':
      case 'charging point':
        icon = Icons.power;
        color = Colors.green;
        break;
      case 'water':
        icon = Icons.local_drink;
        color = Colors.lightBlue;
        break;
      case 'entertainment':
        icon = Icons.tv;
        color = Colors.purple;
        break;
      case 'comfortable seats':
      case 'recliner seats':
        icon = Icons.airline_seat_recline_extra;
        color = Colors.amber.shade800;
        break;
      default:
        icon = Icons.star;
        color = AppColors.primary;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: color,
          ),
          SizedBox(width: 6.w),
          Text(
            amenity,
            style: TextStyle(
              fontSize: 14.sp,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: color,
          ),
        ),
        SizedBox(width: 15.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// **Handles Date & Time Selection**
  Future<void> _selectDateTime() async {
    // Unfocus any text fields
    FocusScope.of(context).unfocus();

    final DateTime now = DateTime.now();

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Generate a random time between 6 AM and 9 PM
      final random = DateTime.now().millisecondsSinceEpoch;
      final randomHour = 6 + (random % 15); // 6 AM to 9 PM
      final randomMinute = (random ~/ 1000) % 60;

      final combinedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        randomHour,
        randomMinute,
      );

      setState(() {
        _dateTimeController.text =
            DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);
      });
      _validateForm();
      getBookedSeats();
    }
  }
}
