import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../components/CustomButton.dart';
import '../../../../components/AppColors.dart';
import '../../../../core/constants.dart';
import '../provider/payment_provider.dart';

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
      final bookState = ref.watch(bookProvider);
      final book = bookState.book;

      final url = Uri.parse('$apiBaseUrl/initialize');
      final body = {
        "bookingId": book?.id,
        "userId": book?.userId,
        "amount": book?.totalFare,
        "website_url": apiBaseUrl,
        "return_url": "$apiBaseUrl/makePayment"
      };

      final response = await http.post(url, body: json.encode(body), headers: {
        "Content-Type": "application/json",
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String paymentId = data['paymentInitiate']["pidx"];
        final paymentUrl = data['paymentInitiate']["payment_url"];

        context.pushNamed(
          '/payment',
          pathParameters: {
            'url': Uri.encodeComponent(paymentUrl),
            'pidx': paymentId
          },
        );
      }
    } catch (e) {
      print('Error initializing payment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookState = ref.watch(bookProvider);
    final book = bookState.book;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Booking Overview",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: bookState.isLoading
          ? _buildLoadingUI()
          : book == null
              ? _buildErrorUI()
              : Stack(
                  children: [
                    // Top curved background
                    Container(
                      height: 30.h,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30.r),
                          bottomRight: Radius.circular(30.r),
                        ),
                      ),
                    ),

                    Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20.w, vertical: 10.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildBookingDetails(book),
                                SizedBox(height: 20.h),
                                _buildPriceDetailsCard(book),
                                SizedBox(height: 20.h),
                                // _buildRouteVisualization(book), // Removed route visualization
                                _buildBookingNotes(),
                                SizedBox(
                                    height: 100.h), // Space for bottom button
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Fixed payment button at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30.r),
                            topRight: Radius.circular(30.r),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: _buildActionButton(book.totalFare ?? 0),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildBookingDetails(book) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.iconColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: AppColors.primary,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Booking ${book.id}",
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    book.bookingDate != null
                        ? book.bookingDate!.split("T")[0]
                        : "N/A",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.pending_actions,
                      size: 14.r,
                      color: AppColors.accent,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      "PENDING",
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                _buildLocationItem(
                  isPickup: true,
                  location: book.pickUpPoint ?? "N/A",
                ),
                Padding(
                  padding: EdgeInsets.only(left: 14.w),
                  child: Column(
                    children: [
                      Container(
                        width: 2.w,
                        height: 30.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary,
                              AppColors.accent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildLocationItem(
                  isPickup: false,
                  location: book.dropOffPoint ?? "N/A",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(
      {required bool isPickup, required String location}) {
    return Row(
      children: [
        Container(
          width: 30.w,
          height: 30.h,
          decoration: BoxDecoration(
            color: isPickup
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.accent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              isPickup ? Icons.trip_origin : Icons.place,
              color: isPickup ? AppColors.primary : AppColors.accent,
              size: 18.r,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isPickup ? "Pickup Location" : "Dropoff Location",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                location.split(',').take(2).join(', '),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceDetailsCard(book) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: AppColors.purple,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                "Price Details",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Price per Seat",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                "Rs. ${book.totalFare / book.bookingSeats.length ?? 0}",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Number of Seats",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                "${book.bookingSeats.length ?? 0}",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Divider(color: AppColors.background, thickness: 1.h),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                "Rs. ${book.totalFare ?? 0}",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // _buildRouteVisualization removed

  Widget _buildBookingNotes() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.buttonColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  color: AppColors.buttonColor,
                  size: 20.r,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                "Booking Information",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoItem(
            icon: Icons.payments_outlined,
            title: "Payment",
            description: "Complete the payment to confirm your booking",
          ),
          SizedBox(height: 12.h),
          _buildInfoItem(
            icon: Icons.schedule,
            title: "Schedule",
            description:
                "Be at the pickup point 10 minutes before departure time",
          ),
          SizedBox(height: 12.h),
          _buildInfoItem(
            icon: Icons.cancel_outlined,
            title: "Cancellation",
            description:
                "Cancellations can be made up to 2 hours before departure",
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16.r,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(int totalFare) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Pay Rs. $totalFare',
        color: AppColors.primary,
        onPressed: _initPayment,
      ),
    );
  }

  Widget _buildLoadingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.sp),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3.w,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            "Fetching booking details...",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Please wait a moment",
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.sp),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 60.r,
              color: AppColors.accent,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            "Error fetching booking details",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Please try again later",
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _fetchBook,
            icon: Icon(Icons.refresh),
            label: Text("Try Again"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
