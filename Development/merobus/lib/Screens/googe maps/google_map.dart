import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:merobus/Components/AppColors.dart';

import '../../Components/CustomButton.dart';
import '../../Components/CustomTextField.dart';
import '../../providers/location_permission.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();

  LatLng? _currentLocation;
  bool isSearching = true;
  bool isLoading = true;

  final TextEditingController _fromLocationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCurrentLocation();
  }

  void _initializeCurrentLocation() async {
    try {
      final location = await getCurrentLocation();
      setState(() {
        _currentLocation = location;
        isLoading = false;
      });
    } catch (e) {
      print(e); // Handle error appropriately
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation!,
                  zoom: 13,
                ),
                compassEnabled: true,
                tiltGesturesEnabled: true,
                myLocationButtonEnabled: false,
                mapType: MapType.terrain,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                onMapCreated: (controller) {
                  _mapController.complete(controller);
                },
                markers: _createMarkers(),
              ),
              Positioned(
                top: 50.h,
                left: 15.w,
                child: FloatingActionButton(
                  heroTag: "back",
                  mini: true,
                  backgroundColor: Colors.white,
                  elevation: 2,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Icon(Icons.arrow_back, size: 25.r),
                ),
              ),
              isSearching
                  ? Positioned(
                      top: 400.h,
                      right: 15.w,
                      child: FloatingActionButton(
                        heroTag: "location",
                        backgroundColor: AppColors.buttonText,
                        foregroundColor: AppColors.primary,
                        onPressed: () {
                          _mapController.future.then((controller) {
                            controller.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                    target: _currentLocation!, zoom: 13),
                              ),
                            );
                          });
                        },
                        child: Icon(Icons.my_location_outlined, size: 25.r),
                      ),
                    )
                  : Positioned(
                      bottom: 90.h,
                      right: 15.w,
                      child: FloatingActionButton(
                        heroTag: "location",
                        backgroundColor: AppColors.buttonText,
                        foregroundColor: AppColors.primary,
                        onPressed: () {
                          _mapController.future.then((controller) {
                            controller.animateCamera(
                              CameraUpdate.newCameraPosition(
                                CameraPosition(
                                    target: _currentLocation!, zoom: 13),
                              ),
                            );
                          });
                        },
                        child: Icon(Icons.my_location_outlined, size: 25.r),
                      ),
                    ),
              isSearching
                  ? Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 10.w,
                          right: 10.w,
                        ),
                        child: Container(
                          height: 378.h,
                          width: 375.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(30.r)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, -3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(
                                top: 10.h, left: 20.w, right: 20.w),
                            child: Column(
                              children: [
                                SizedBox(height: 10.h),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Search Your ",
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors
                                              .black, // Black for "Search Your"
                                        ),
                                      ),
                                      TextSpan(
                                        text: "Route",
                                        style: TextStyle(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors
                                              .primary, // AppColors.primary for "Route"
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Row(
                                  children: [
                                    Text('From',
                                        style: TextStyle(fontSize: 16.sp)),
                                  ],
                                ),
                                SizedBox(height: 5.h),
                                CustomTextField(
                                  hint: 'From Location',
                                  icon: Icons.location_on_outlined,
                                  suffixIcon: Icons.my_location_outlined,
                                  borderColor: Colors.transparent,
                                  backgroundColor: const Color(0xffF6F8FA),
                                  controller: _fromLocationController,
                                  onSuffixTap: () async {
                                    try {
                                      final location =
                                          await getCurrentLocation();
                                      _fromLocationController.text =
                                          '${location.latitude}, ${location.longitude}';
                                    } catch (e) {
                                      print(e); // Handle error appropriately
                                    }
                                  },
                                ),
                                SizedBox(height: 20.h),
                                Row(
                                  children: [
                                    Text('To',
                                        style: TextStyle(fontSize: 16.sp)),
                                  ],
                                ),
                                SizedBox(height: 5.h),
                                CustomTextField(
                                  hint: 'To Location',
                                  icon: Icons.location_on_outlined,
                                  borderColor: Colors.transparent,
                                  backgroundColor: const Color(0xffF6F8FA),
                                  suffixIcon: Icons.map_outlined,
                                  controller: TextEditingController(),
                                ),
                                SizedBox(height: 30.h),
                                CustomButton(
                                  color: AppColors.primary,
                                  text: 'Find Now',
                                  onPressed: () {
                                    setState(() {
                                      isSearching = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : Positioned(
                      bottom: 30.h,
                      right: 15.w,
                      child: FloatingActionButton(
                        heroTag: "search",
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        onPressed: () {
                          setState(() {
                            isSearching = true;
                          });
                        },
                        child: Icon(Icons.search, size: 25.r),
                      ),
                    ),
            ]),
    );
  }

  @override
  void dispose() {
    _fromLocationController.dispose();
    super.dispose();
  }

  Set<Marker> _createMarkers() {
    return {
      if (_currentLocation != null)
        Marker(
          markerId: const MarkerId("_currentLocation"),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarker,
        ),
    };
  }
}
