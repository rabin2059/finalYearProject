import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/components/CustomButton.dart';
import 'package:frontend/user/Passenger/bus%20details/providers/bus_details_provider.dart';
import 'package:frontend/user/Passenger/bus%20details/providers/single_bus_state.dart';
import 'package:go_router/go_router.dart';

import '../../../../components/AppColors.dart';
import '../../../../core/constants.dart';

class BusDetailScreen extends ConsumerStatefulWidget {
  const BusDetailScreen({super.key, required this.busId});
  final int busId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BusDetailScreenState();
}

class _BusDetailScreenState extends ConsumerState<BusDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(busDetailsProvider.notifier).fetchBusDetail(widget.busId));
  }

  /// **Fetch Bus Details**
  Future<void> _fetchBusDetails() async {
    try {
      await ref.read(busDetailsProvider.notifier).fetchBusDetail(widget.busId);
    } catch (e) {
      debugPrint("Error fetching bus details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final busDetailState = ref.watch(busDetailsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bus Information"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: busDetailState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : busDetailState.error.isNotEmpty
              ? Center(child: Text(busDetailState.error))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBusInfoCard(busDetailState),
                      SizedBox(height: 16.h),
                      _buildImageGallery(),
                      SizedBox(height: 16.h),
                      _buildDriverDetails(busDetailState),
                      SizedBox(height: 40.h),
                      CustomButton(
                          text: "Book Seat",
                          onPressed: () {
                            context.pushNamed('/book', pathParameters: {
                              'id': widget.busId.toString()
                            });
                          }),
                      SizedBox(height: 10.h),
                      CustomButton(
                          text: "Chat",
                          onPressed: () {
                            context.pushNamed('/chat');
                          }),
                    ],
                  ),
                ),
    );
  }

  /// **Bus Information Card**
  Widget _buildBusInfoCard(busDetailState) {
    final vehicle = busDetailState.vehicle;

    if (vehicle == null) {
      return const SizedBox();
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                radius: 20.r,
                child: const Icon(Icons.directions_bus, color: Colors.blue),
              ),
              SizedBox(width: 10.w),
              Text(
                "Bus No ${vehicle.vehicleNo ?? 'N/A'} ",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text("₹${vehicle.route[0].fare ?? 'N/A'}",
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green)),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.black54),
              SizedBox(width: 5.w),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(vehicle.departure ?? 'N/A',
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text('-'),
                  Text(vehicle.arrivalTime ?? 'N/A',
                      style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              _buildTag("1:15 h"),
              SizedBox(width: 10.w),
              _buildTag(
                  "${(vehicle.vehicleSeat?.length ?? 0) - (vehicle.booking?.fold(0, (sum, booking) => sum + (booking.bookingSeats?.length ?? 0)) ?? 0)} Seats"),
              const Spacer(),
              _buildRatingTag("4.5"),
            ],
          ),
        ],
      ),
    );
  }

  /// **Image Gallery**
  Widget _buildImageGallery() {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Image.asset("assets/bus1.png",
                fit: BoxFit.cover, height: 120.h),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child:
                Image.asset("assets/bus.png", fit: BoxFit.cover, height: 120.h),
          ),
        ),
      ],
    );
  }

  /// **Driver Details Section**
  Widget _buildDriverDetails(busDetailState) {
    final owner = busDetailState.vehicle?.owner;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          // Driver Image
          ClipRRect(
            borderRadius: BorderRadius.circular(50.r),
            child: owner?.images != null && owner!.images!.isNotEmpty
                ? Image.network(
                    imageUrl + owner!.images!, // Ensure it's a valid URL
                    width: 60.w,
                    height: 60.h,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        "assets/profile.png", // Fallback image
                        width: 60.w,
                        height: 60.h,
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    "assets/profile.png", // Default placeholder image
                    width: 60.w,
                    height: 60.h,
                    fit: BoxFit.cover,
                  ),
          ),
          SizedBox(width: 15.w),

          // Driver Details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Driver: ${owner?.username ?? 'N/A'}",
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 5.h),
              Row(
                children: [
                  Icon(Icons.phone, color: Colors.green, size: 18),
                  SizedBox(width: 5.w),
                  Text(owner?.phone ?? 'N/A',
                      style: TextStyle(fontSize: 14.sp, color: Colors.black87)),
                ],
              ),
            ],
          ),
          const Spacer(),

          // Call Button
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.call, color: Colors.green, size: 28),
          ),
        ],
      ),
    );
  }

  /// **Small Tag Component**
  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(text, style: TextStyle(fontSize: 12.sp, color: Colors.black)),
    );
  }

  /// **Rating Tag**
  Widget _buildRatingTag(String rating) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.r),
        color: Colors.green.shade600,
      ),
      child: Text("⭐ $rating",
          style: TextStyle(fontSize: 12.sp, color: Colors.white)),
    );
  }
}
