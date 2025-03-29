import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../../data/models/user_model.dart';
import '../../../../user/Driver/booking lists/providers/book_vehicle_provider.dart';

class BookingUserDetails extends ConsumerStatefulWidget {
  const BookingUserDetails({
    super.key, 
    required this.bookId, 
    required this.userId
  });

  final int bookId;
  final int userId;

  @override
  ConsumerState<BookingUserDetails> createState() => _BookingUserDetailsState();
}

class _BookingUserDetailsState extends ConsumerState<BookingUserDetails> {
  UserData? userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    final url = Uri.parse("$apiBaseUrl/getUser?id=${widget.userId}");
    try {
      final response = await http.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data != null && data['userData'] != null) {
          setState(() {
            userData = UserData.fromJson(data['userData']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          print('No user data found.');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        print('Failed to fetch user data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching user data: $e');
    }
  }

  String addressSplitter({required String address}) {
    final parts = address.split(',');
    if (parts.length > 2) {
      return parts.sublist(0, parts.length - 2).join(',').trim();
    }
    return address;
  }

  // Phone call method
  void _launchPhoneCall(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to initiate call'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred'),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookVehicleProvider);
    final booking = bookingState.bookingByVehicle?.firstWhere(
      (element) => element.id == widget.bookId,
    );

    String bookingDate = booking != null
        ? DateFormat('yyyy-MM-dd')
            .format(DateTime.parse(booking.bookingDate ?? ''))
        : '-';
    String bookingTime = booking != null
        ? DateFormat('hh:mm a')
            .format(DateTime.parse(booking.bookingDate ?? ''))
        : '-';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Ride Details',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primary),
        actions: [
          // Call button in AppBar
          if (userData != null && userData!.phone != null)
            IconButton(
              icon: Icon(Icons.call, color: AppColors.primary),
              onPressed: () => _launchPhoneCall(userData!.phone!),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ride Information Section
              _buildSectionTitle('Ride Information'),
              Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.location_on,
                    iconColor: AppColors.primary,
                    label: 'Pickup Point',
                    value: booking?.pickUpPoint != null
                        ? addressSplitter(address: booking!.pickUpPoint!)
                        : '-',
                  ),
                  _buildDivider(),
                  _buildDetailRow(
                    icon: Icons.location_off,
                    iconColor: AppColors.accent,
                    label: 'Drop-off Point',
                    value: booking?.dropOffPoint != null
                        ? addressSplitter(address: booking!.dropOffPoint!)
                        : '-',
                  ),
                  _buildDivider(),
                  _buildDetailRow(
                    icon: Icons.monetization_on,
                    iconColor: AppColors.secondary,
                    label: 'Fare',
                    value: 'Rs. ${booking?.totalFare ?? '-'}',
                  ),
                  _buildDivider(),
                  _buildDetailRow(
                    icon: Icons.check_circle,
                    iconColor: AppColors.primary,
                    label: 'Status',
                    value: booking?.status ?? '-',
                  ),
                  _buildDivider(),
                  _buildDetailRow(
                    icon: Icons.calendar_today,
                    iconColor: AppColors.secondary,
                    label: 'Booking Date',
                    value: bookingDate,
                  ),
                  _buildDivider(),
                  _buildDetailRow(
                    icon: Icons.access_time,
                    iconColor: AppColors.accent,
                    label: 'Booking Time',
                    value: bookingTime,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Passenger Details Section
              _buildSectionTitle('Passenger Details'),
              _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.person_outline,
                          iconColor: AppColors.primary,
                          label: 'Name',
                          value: userData?.username ?? "N/A",
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.phone,
                          iconColor: AppColors.secondary,
                          label: 'Phone',
                          value: userData?.phone ?? "N/A",
                        ),
                        _buildDivider(),
                        _buildDetailRow(
                          icon: Icons.email,
                          iconColor: AppColors.accent,
                          label: 'Email',
                          value: userData?.email ?? "N/A",
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // Section Title Widget
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // Divider Widget
  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.shade200,
      height: 1,
      thickness: 0.5,
    );
  }

  // Detail Row Widget
  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Color Usage
class AppColors {
  static const Color primary = Color(0xFF88BD41); // Main theme color
  static const Color secondary = Color(0xFF03DAC5); // Accent and supporting color
  static const Color accent = Color(0xFFFF5722); // Highlight and error states
  static const Color background = Color(0xFFF5F5F5); // Light background
  static const Color textPrimary = Color(0xFF000000); // Main text color
  static const Color textSecondary = Color(0xFF828282); // Secondary text color
  static const Color buttonColor = Color(0xFF2196F3); // Button background
  static const Color buttonText = Color(0xFFFFFFFF); // Button text
  static const Color iconColor = Color(0xFFCBF691); // Supporting icon color
}