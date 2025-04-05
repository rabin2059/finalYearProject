import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../components/AppColors.dart';
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
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchBusData,
          color: AppColors.primary,
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _buildSearchFields(),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Buses',
                      style: TextStyle(
                        fontSize: 18.sp, 
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.pushNamed('/bookings');
                      },
                      child: Container(
                        height: 36.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(18.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w, 
                            vertical: 4.h
                          ),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.doc_checkmark_fill,
                                size: 16.h,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                "My Bookings",
                                style: TextStyle(
                                  fontSize: 14.sp, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
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

  /// Builds app header
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Find Your",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black54,
                ),
              ),
              Text(
                "Perfect Bus Route",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Spacer(),
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            radius: 18.r,
            child: Icon(
              Icons.person_outline,
              color: AppColors.primary,
              size: 22.sp,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds Search Fields with a Loading Indicator
  Widget _buildSearchFields() {
    final busState = ref.watch(busProvider);

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                _buildSearchTextField('From'),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            height: 50.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Colors.redAccent,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                _buildSearchTextField('To'),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            height: 48.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  Color.fromARGB(255, 61, 153, 223),
                ],
              ),
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _fetchBusData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: busState.loading
                ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search),
                      SizedBox(width: 8.w),
                      Text(
                        "Find Buses",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Search TextField Component
  Widget _buildSearchTextField(String hint) {
    return Expanded(
      child: TextFormField(
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.transparent,
          hintStyle: TextStyle(fontSize: 15.sp, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  /// Builds Bus List UI
  Widget _buildBusList(busState) {
    if (busState.loading && busState.buses.isEmpty) {
      return _buildLoadingShimmer();
    }

    if (busState.errorMessage.isNotEmpty) {
      return _buildErrorWidget(busState.errorMessage);
    }

    if (busState.buses.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
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

  /// Loading shimmer effect
  Widget _buildLoadingShimmer() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 16.h),
            height: 130.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 80.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.r),
                      bottomLeft: Radius.circular(12.r),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 150.w,
                          height: 18.h,
                          color: Colors.grey.shade200,
                        ),
                        Container(
                          width: 100.w,
                          height: 16.h,
                          color: Colors.grey.shade200,
                        ),
                        Container(
                          width: 180.w,
                          height: 16.h,
                          color: Colors.grey.shade200,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 60.w,
                  color: Colors.grey.shade100,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 80.sp,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16.h),
          Text(
            "No buses available",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Try changing your search criteria",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: _fetchBusData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              "Refresh",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Error Widget with Retry Button
  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60.sp,
            color: Colors.redAccent,
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp, 
                color: Colors.red.shade800
              ),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _fetchBusData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            icon: const Icon(Icons.refresh),
            label: Text(
              "Try Again",
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(bus) {
    final route = bus.route;
    final booking = bus.booking;

    String getFirstWord(String? location) {
      if (location == null || location.isEmpty) return 'Unknown';
      return location.split(',').first.trim();
    }

    DateTime? departureTime;
    DateTime? arrivalTime;
    
    try {
      if (bus.departure != null) {
        departureTime = DateTime.parse(bus.departure!);
      }
      if (bus.arrivalTime != null) {
        arrivalTime = DateTime.parse(bus.arrivalTime!);
      }
    } catch (e) {
      debugPrint("Error parsing date: $e");
    }

    final startLocation = getFirstWord(route?.startPoint);
    final endLocation = getFirstWord(route?.endPoint);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top colored part
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                _buildBusIcon(),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus.model ?? 'Unknown Bus',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        bus.vehicleNo ?? 'N/A',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '4.5',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main content
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Journey time visualization
                Row(
                  children: [
                    // Start time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          departureTime != null
                              ? DateFormat.jm().format(departureTime)
                              : 'N/A',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          startLocation,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    
                    Expanded(
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 2.h,
                              color: Colors.grey.shade300,
                            ),
                            Icon(
                              Icons.directions_bus,
                              color: AppColors.primary,
                              size: 18.sp,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // End time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          arrivalTime != null
                              ? DateFormat.jm().format(arrivalTime)
                              : 'N/A',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          endLocation,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                SizedBox(height: 16.h),
                
                // Price and book button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Price per seat",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          "रु ${route?.fare ?? 0}",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.pushNamed('/busDetail', 
                            pathParameters: {'id': bus.id.toString()});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: Text(
                        "View Detail",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusIcon() {
    return Container(
      height: 44.h,
      width: 44.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        CupertinoIcons.bus,
        color: Colors.white,
        size: 22.sp,
      ),
    );
  }
}