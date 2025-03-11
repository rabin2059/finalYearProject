import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../components/AppColors.dart';
import '../../../../components/CustomButton.dart';
import '../../../../core/constants.dart';
import '../providers/bus_details_provider.dart';

class BusDetailScreen extends ConsumerStatefulWidget {
  const BusDetailScreen({super.key, required this.busId});

  final int busId;

  @override
  ConsumerState<BusDetailScreen> createState() => _BusDetailScreenState();
}

class _BusDetailScreenState extends ConsumerState<BusDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(busDetailsProvider.notifier).fetchBusDetail(widget.busId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busDetailState = ref.watch(busDetailsProvider);

    final vehicle = busDetailState.vehicle;

    int bookedSeatsCount = vehicle?.booking?.where((b) {
          final bookingDate = DateTime.parse(b.bookingDate ?? '');
          final tomorrow = DateTime.now().add(const Duration(days: 1));
          return bookingDate.year == tomorrow.year &&
              bookingDate.month == tomorrow.month &&
              bookingDate.day == tomorrow.day;
        }).fold(
            0, (sum, booking) => sum! + (booking.bookingSeats?.length ?? 0)) ??
        0;

    final seatCount = (vehicle!.vehicleSeat?.length ?? 0) - bookedSeatsCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bus Information"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ref.watch(busDetailsProvider).isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBusInfoCard(),
                  SizedBox(height: 16.h),
                  _buildImageGallery(),
                  SizedBox(height: 16.h),
                  _buildDriverDetails(),
                  SizedBox(height: 40.h),
                  CustomButton(
                    text: "Book Seat",
                    onPressed: () =>
                        context.pushNamed('/book', pathParameters: {
                      'id': widget.busId.toString(),
                    }),
                  ),
                  SizedBox(height: 10.h),
                  CustomButton(
                    text: "Chat",
                    onPressed: () => context.pushNamed('/chat'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBusInfoCard() {
    final vehicle = ref.watch(busDetailsProvider).vehicle;

    final bookedSeatsCount = vehicle?.booking?.where((b) {
          final bookingDate = DateTime.parse(b.bookingDate ?? "");
          final tomorrow = DateTime.now().add(const Duration(days: 1));
          return bookingDate.year == tomorrow.year &&
              bookingDate.month == tomorrow.month &&
              bookingDate.day == tomorrow.day;
        }).fold(
            0, (sum, booking) => sum + (booking.bookingSeats?.length ?? 0)) ??
        0;

    final availableSeats =
        (vehicle?.vehicleSeat?.length ?? 0) - bookedSeatsCount;

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
                "Bus No ${vehicle?.vehicleNo ?? 'N/A'}",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text("₹${vehicle?.route?[0].fare ?? 'N/A'}",
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green)),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(vehicle?.departure ?? 'N/A',
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text('-'),
              Text(vehicle?.arrivalTime ?? 'N/A',
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              _buildTag("1:15 h"),
              SizedBox(width: 10.w),
              _buildTag("$availableSeats Seats"),
              const Spacer(),
              _buildRatingTag("4.5"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverDetails() {
    final owner = ref.watch(busDetailsProvider).vehicle?.owner;

    return Row(
      children: [
        CircleAvatar(
          radius: 30.r,
          backgroundImage: owner?.images != null
              ? NetworkImage(imageUrl + owner!.images!)
              : const AssetImage("assets/profile.png") as ImageProvider,
        ),
        SizedBox(width: 15.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Driver: ${owner?.username ?? 'N/A'}",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            Text(owner?.phone ?? 'N/A',
                style: TextStyle(fontSize: 14.sp, color: Colors.black87)),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () => launchUrl(Uri(scheme: 'tel', path: owner?.phone)),
          icon: const Icon(Icons.call, color: Colors.green, size: 28),
        ),
      ],
    );
  }

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

  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Text(text, style: TextStyle(fontSize: 12.sp)),
    );
  }

  Widget _buildRatingTag(String rating) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Text('⭐️ $rating', style: TextStyle(fontSize: 12.sp)),
    );
  }
}
