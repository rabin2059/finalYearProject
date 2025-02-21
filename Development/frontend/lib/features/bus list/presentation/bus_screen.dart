import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../components/AppColors.dart';
import '../providers/bus_list_provider.dart';

class BusScreen extends ConsumerStatefulWidget {
  const BusScreen({super.key});

  @override
  ConsumerState<BusScreen> createState() => _BusScreenState();
}

class _BusScreenState extends ConsumerState<BusScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(busProvider.notifier).fetchBusList());
  }

  /// Fetch Bus Data
  Future<void> _fetchBusData() async {
    try {
      await ref.read(busProvider.notifier).fetchBusList();
    } catch (e) {
      debugPrint("Error fetching buses: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final busState = ref.watch(busProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Column(
            children: [
              _buildSearchFields(),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Buses',
                    style:
                        TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.pushNamed('/bookings');
                    },
                    child: Container(
                      height: 30.h,
                      // width: 40.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 2.h),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.doc_checkmark_fill,
                              size: 16.h,
                            ),
                            Text(
                              "Booking",
                              style: TextStyle(
                                  fontSize: 16.sp, fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(height: 10.h),
              Expanded(
                child: _buildBusList(busState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds Search Fields with a Loading Indicator
  Widget _buildSearchFields() {
    final busState = ref.watch(busProvider);

    return Container(
      height: 50.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          _buildSearchTextField('From'),
          busState.loading
              ? Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: SizedBox(
                    height: 18.h,
                    width: 18.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(CupertinoIcons.arrow_2_circlepath),
          _buildSearchTextField('To'),
        ],
      ),
    );
  }

  /// Search TextField Component
  Widget _buildSearchTextField(String hint) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w),
        child: TextFormField(
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.transparent,
            hintStyle: TextStyle(fontSize: 15.sp),
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          ),
        ),
      ),
    );
  }

  /// Builds Bus List UI
  Widget _buildBusList(busState) {
    if (busState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (busState.errorMessage.isNotEmpty) {
      return _buildErrorWidget(busState.errorMessage);
    }

    return ListView.builder(
      itemCount: busState.buses.length,
      itemBuilder: (context, index) {
        final bus = busState.buses[index];
        return GestureDetector(
          onTap: () => context.pushNamed('/busDetail',
              pathParameters: {'id': bus.id.toString()}),
          child: _buildBusCard(bus),
        );
      },
    );
  }

  /// Error Widget with Retry Button
  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, color: Colors.red)),
          SizedBox(height: 10.h),
          ElevatedButton(
            onPressed: _fetchBusData,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text("Retry",
                style: TextStyle(fontSize: 14.sp, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Builds Individual Bus Card
  Widget _buildBusCard(bus) {
    final route = bus.route; // Route is already an object, no need for [0]
    final seatCount = bus.vehicleSeat?.length ?? 0;
    final owner = bus.owner;
    final booking = (bus.booking != null && bus.booking!.isNotEmpty)
        ? bus.booking![0]
        : null;

    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildBusIcon(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(bus.model ?? 'Unknown Bus',
                          style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary)),
                      Text('-'),
                      Text(bus.vehicleNo ?? 'N/A',
                          style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                    ]),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(bus.departure ?? 'N/A',
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        Text('-'),
                        Text(bus.arrivalTime ?? 'N/A',
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(route?.startPoint ?? 'Unknown Start',
                              style: TextStyle(fontSize: 14.sp)),
                          Text('-'),
                          Text(route?.endPoint ?? 'Unknown End',
                              style: TextStyle(
                                fontSize: 14.sp,
                              )),
                        ]),
                    SizedBox(
                      height: 5.h,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 5.w),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                      child: Text(
                          "Seats Available: ${(bus.vehicleSeat?.length ?? 0) - (bus.booking?.fold(0, (sum, booking) => sum + (booking.bookingSeats?.length ?? 0)) ?? 0)} Seats",
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                    ),
                  ],
                ),
              ),
            ),
            _buildPriceAndRating(route?.fare ?? 0),
          ],
        ),
      ),
    );
  }

  /// Bus Icon Widget
  Widget _buildBusIcon() {
    return Container(
      height: 50.h,
      width: 50.w,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
      ),
      child: const Icon(CupertinoIcons.bus, color: Colors.white),
    );
  }

  /// Price and Rating UI
  Widget _buildPriceAndRating(int fare) {
    return Column(
      children: [
        Text("Rs. $fare",
            style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green)),
        SizedBox(height: 5.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(5.r),
          ),
          child: Text('⭐️ 4.5',
              style: TextStyle(fontSize: 12.sp, color: Colors.white),
              textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
