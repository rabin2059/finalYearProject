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
  const BookingUserDetails(
      {super.key, required this.bookId, required this.userId});

  final int bookId;
  final int userId;

  @override
  ConsumerState<BookingUserDetails> createState() => _BookingUserDetailsState();
}

class _BookingUserDetailsState extends ConsumerState<BookingUserDetails> {
  UserData? userData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    final url = Uri.parse("$apiBaseUrl/getUser?id=${widget.userId}");
    final response = await http.get(url);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);

      if (data != null && data['userData'] != null) {
        setState(() {
          userData = UserData.fromJson(data['userData']);
        });
      } else {
        print('No user data found.');
      }
    } else {
      print('Failed to fetch user data: ${response.statusCode}');
    }
  }

  String formatLocation(String address) {
    final parts = addressSplitter(address: address);
    return parts;
  }

  String addressSplitter({required String address}) {
    final parts = address.split(',');
    if (parts.length > 2) {
      return parts.sublist(0, parts.length - 2).join(',').trim();
    }
    return address;
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookVehicleProvider);
    final booking = bookingState.bookingByVehicle?.firstWhere(
      (element) => element.id == widget.bookId,
      // orElse: () => BookingByVehicle(), // Provide a default instance
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
      appBar: AppBar(
        title: const Text('Booking User Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow('Booking ID:', widget.bookId.toString()),
                    _detailRow(
                        'Pickup Point:',
                        booking?.pickUpPoint != null
                            ? addressSplitter(address: booking!.pickUpPoint!)
                            : '-'),
                    _detailRow(
                        'Drop-off Point:',
                        booking?.dropOffPoint != null
                            ? addressSplitter(address: booking!.dropOffPoint!)
                            : '-'),
                    _detailRow('Fare:', 'Rs. ${booking?.totalFare ?? '-'}'),
                    _detailRow('Status:', booking?.status ?? '-'),
                    const SizedBox(height: 8),
                    _detailRow('Booking Date:', bookingDate),
                    _detailRow('Booking Time:', bookingTime),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'User Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: userData == null
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow('Name:', userData!.username ?? ""),
                          _detailRow('Phone:', userData!.phone ?? ""),
                          _detailRow('Email:', userData!.email ?? ""),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _launchPhoneCall(userData?.phone ?? ''),
                icon: const Icon(Icons.call),
                label: const Text('Call User'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPhoneCall(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to initiate call')),
      );
    }
  }
}
