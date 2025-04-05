import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/components/CustomButton.dart';
import 'package:frontend/user/Passenger/payment/provider/payment_provider.dart';
import 'package:frontend/user/Passenger/booking%20lists/providers/book_list_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants.dart';

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key, required this.bookId});
  final int bookId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchBook());
    _initPayment();
  }

  Future<void> _fetchBook() async {
    try {
      await ref.read(bookProvider.notifier).fetchBook(widget.bookId);
    } catch (e) {
      print('Error fetching book: $e');
    }
  }

  Future<void> _initPayment() async {
    try {
      final bookState = ref.watch(bookProvider); // ✅ Use `watch` for reactivity
      final book = bookState.book; // ✅ Extract book from state

      final url = Uri.parse('$apiBaseUrl/initialize');
      final body = {
        "bookingId": book?.id,
        "userId": book?.userId,
        "amount": book?.totalFare,
        "website_url": "http://localhost:3089"
      };

      final response = await http.post(url, body: json.encode(body), headers: {
        "Content-Type": "application/json",
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String paymentId = data['paymentInitiate']["pidx"];
        print(paymentId);
        final paymentUrl = data['paymentInitiate']["payment_url"];
        print(paymentUrl);

        context.pushNamed(
          '/payment',
          pathParameters: {
            'url': Uri.encodeComponent(paymentUrl)
          }, // ✅ Encode URL properly
        );
      }
    } catch (e) {
      print('Error initializing payment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookState = ref.watch(bookProvider); // ✅ Use `watch` for reactivity
    final book = bookState.book; // ✅ Extract book from state

    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Overview"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blueAccent,
      ),
      body: bookState.isLoading
          ? _buildLoadingUI()
          : book == null
              ? _buildErrorUI()
              : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.w, vertical: 10.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 🔹 Booking Details Card
                            _buildBookingDetails(book),

                            SizedBox(height: 20.h),

                            // **Map View**
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: FlutterMap(
                                  options: MapOptions(
                                    
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      subdomains: ['a', 'b', 'c'],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // **Proceed to Payment Button**
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 20.h),
                      child: _buildActionButton(book.totalFare ?? 0),
                    ),
                  ],
                ),
    );
  }

  /// 🎨 **Booking Details Card**
  Widget _buildBookingDetails(book) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_bus, color: Colors.blueAccent, size: 28.w),
              SizedBox(width: 10.w),
              Text(
                "Ongoing Booking Details",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          Divider(thickness: 1.5, color: Colors.grey.shade300),
          SizedBox(height: 10.h),
          _buildDetailRow("Book ID", "${book.id}"),
          _buildDetailRow("Pick-up Location", book.pickUpPoint ?? "N/A"),
          _buildDetailRow("Drop-off Location", book.dropOffPoint ?? "N/A"),
          _buildDetailRow(
              "Date and Time",
              book.bookingDate != null
                  ? book.bookingDate!.split("T")[0]
                  : "N/A"),
        ],
      ),
    );
  }

  /// 🎨 **Dynamic Action Button Logic**
  Widget _buildActionButton(int totalFare) {
    return CustomButton(
        text: 'Pay Rs.$totalFare',
        onPressed: () {
          _initPayment();
        });
  }

  /// 🔥 **Loading UI**
  Widget _buildLoadingUI() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 10),
          Text(
            "Fetching booking details...",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 🔥 **Error UI**
  Widget _buildErrorUI() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 10),
          Text(
            "Error fetching booking details",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// **Reusable Row Widget for Booking Details**
  Widget _buildDetailRow(String title, String value) {
    final displayValue = value.split(',').take(2).join(', ');
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
          SizedBox(
            width: 150.w,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                displayValue,
                style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
