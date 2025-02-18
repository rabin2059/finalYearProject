import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:merobus/Components/AppColors.dart';

import '../../Services/api_service.dart';
import '../../models/busStop.dart';

class BusScreen extends StatefulWidget {
  const BusScreen({super.key, required this.dept});
  final int dept;

  @override
  State<BusScreen> createState() => _BusScreenState();
}

class _BusScreenState extends State<BusScreen> {
  late Future<List<Vehicle>> _vehiclesFuture;
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _vehiclesFuture = apiService.fetchVehicles(); // Fetch vehicles dynamically
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Search fields
              Container(
                height: 50.h,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 160.w,
                      height: 30.h,
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: 'From',
                          filled: true,
                          fillColor: Colors.transparent,
                          hintStyle: TextStyle(fontSize: 15.sp),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                        ),
                      ),
                    ),
                    const Icon(CupertinoIcons.arrow_2_circlepath),
                    SizedBox(
                      width: 160.w,
                      height: 30.h,
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: 'To',
                          filled: true,
                          fillColor: Colors.transparent,
                          hintStyle: TextStyle(fontSize: 15.sp),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'Favourite',
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 10.h),
              // List of bus details
              Expanded(
                child: FutureBuilder<List<Vehicle>>(
                  future: _vehiclesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No buses available',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      );
                    }

                    final vehicles = snapshot.data!;

                    return ListView.builder(
                      itemCount: vehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = vehicles[index];
                        return Card(
                          color: Colors.white,
                          margin: EdgeInsets.symmetric(vertical: 8.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 10.h,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Bus Icon
                                Container(
                                  height: 50.h,
                                  width: 50.w,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.bus,
                                    color: Colors.white,
                                  ),
                                ),
                                // Bus Details
                                Expanded(
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10.w),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vehicle.model ?? 'Unknown Bus',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 5.h),
                                        Text(
                                          vehicle.vehicleNo ?? 'N/A',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Text(
                                          vehicle.route?.startPoint ??
                                              'Unknown Route',
                                          style: TextStyle(fontSize: 14.sp),
                                        ),
                                        Text(
                                          vehicle.route?.endPoint ?? 'N/A',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Placeholder for Price and Rating
                                Column(
                                  children: [
                                    Text(
                                      "Rs. 1300",
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    SizedBox(height: 5.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 5.w,
                                        vertical: 2.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(5.r),
                                      ),
                                      child: Text(
                                        '⭐️ 4.5', // Replace with actual rating if available
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
