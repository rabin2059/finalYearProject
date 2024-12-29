import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:merobus/Components/AppColors.dart';

class BusScreen extends StatefulWidget {
  const BusScreen({super.key, required this.dept});
  final int dept;

  @override
  State<BusScreen> createState() => _BusScreenState();
}

class _BusScreenState extends State<BusScreen> {
  // Mock data for buses
  final List<Map<String, String>> buses = [
    {
      'busName': 'TikTok',
      'vehicleNo': 'BA 1 KHA 412',
      'arrival': '7:00 AM - 3:00 PM',
      'route': 'Kathmandu - Gaighat',
      'rate': '4.5'
    },
    {
      'busName': 'Messenger',
      'vehicleNo': 'KHA 1 JA 234',
      'arrival': '6:00 AM - 5:00 PM',
      'route': 'Dharan - Kathmandu',
      'rate': '4.7'
    },
    {
      'busName': 'Himali',
      'vehicleNo': 'BA 4 KHA 321',
      'arrival': '6:00 AM - 6:00 PM',
      'route': 'Itahari - Kathmandu',
      'rate': '4.8'
    },
  ];

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
                child: ListView.builder(
                  itemCount: buses.length,
                  itemBuilder: (context, index) {
                    final bus = buses[index];
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
                                padding: EdgeInsets.symmetric(horizontal: 10.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bus['busName'] ?? 'Unknown Bus',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 5.h),
                                    Text(
                                      bus['vehicleNo'] ?? 'N/A',
                                      style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary),
                                    ),
                                    Text(
                                      bus['route'] ?? 'N/A',
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                                    Text(
                                      bus['arrival'] ?? 'N/A',
                                      style: TextStyle(
                                          fontSize: 14.sp,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Price and Rating
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
                                    borderRadius: BorderRadius.circular(5.r),
                                  ),
                                  child: Text(
                                    '⭐️ ${bus['rate'] ?? 'N/A'}',
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
