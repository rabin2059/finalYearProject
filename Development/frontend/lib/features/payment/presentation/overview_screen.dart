import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/components/CustomButton.dart';
import 'package:go_router/go_router.dart';

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key, required this.bookId});
  final int bookId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Overview"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Booking Details Card
                  Container(
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
                            Icon(Icons.directions_bus,
                                color: Colors.blueAccent, size: 28.w),
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
                        _buildDetailRow("Book ID", "#${widget.bookId}"),
                        _buildDetailRow("Title", "Sample Bus Ride"),
                        _buildDetailRow(
                            "Pick-up Location", "Dharan-12, Mangalbare"),
                        _buildDetailRow(
                            "Drop-off Location", "Ghatthaghar-1, Bhaktapur"),
                        _buildDetailRow(
                            "Date and Time", "20th Feb 2025, 07:00 AM"),
                        _buildDetailRow("Seat No.", "A12, A13"),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // **Map View Placeholder - Takes Most of Remaining Space**
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: Text(
                          "Map View Placeholder",
                          style:
                              TextStyle(fontSize: 16.sp, color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // **Pinned "Proceed to Payment" Button at Bottom**
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: CustomButton(
                text: 'Proceed to Payment',
                onPressed: () {
                  context.pushNamed('/payment',
                      pathParameters: {'id': widget.bookId.toString()});
                }),
          )
        ],
      ),
    );
  }

  /// **Reusable Row Widget for Booking Details**
  Widget _buildDetailRow(String title, String value) {
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
          Text(
            value,
            style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
