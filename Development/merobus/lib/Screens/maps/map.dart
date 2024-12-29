// Import required packages
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:merobus/Components/AppColors.dart';
import 'package:http/http.dart' as http;

import '../../Components/CustomButton.dart';
import '../../Components/CustomTextField.dart';
import '../../providers/location_permission.dart';

// Main map screen widget
class MapScreens extends StatefulWidget {
  const MapScreens({super.key});

  @override
  State<MapScreens> createState() => _MapScreensState();
}

class _MapScreensState extends State<MapScreens> {
  // Controllers
  final MapController _controller = MapController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  TextEditingController? _activeController;

  // Location related variables
  LatLng? _currentLocation;
  LatLng? _startLocation;
  LatLng? _endLocation;
  List<LatLng> routePoints = [];

  // UI state variables
  List<dynamic> _searchResults = [];
  bool isLoading = false;
  bool isSearching = true;
  final bool _isRouteExpanded = false;

  double _currentZoom = 13.0;
  bool _showMarker = true;

  @override
  void initState() {
    super.initState();
    // Add listener for search text changes
    _searchController.addListener(() {
      _searchPlaces(_searchController.text);
    });
    // Initialize user's location
    _initializeLocation();
  }

  // Initialize the user's current location
  Future<void> _initializeLocation() async {
    try {
      Position position = await _getCurrentLocation();
      LatLng currentLatlng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentLocation = currentLatlng;
        });
        _controller.move(currentLatlng, 15.h);
      }
    } catch (e) {
      print('Error getting initial location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(children: [
              // Main map widget
              FlutterMap(
                mapController: _controller,
                options: MapOptions(
                  initialZoom: _currentZoom,
                  initialCenter: _currentLocation ??
                      const LatLng(27.7172,
                          85.3240), // Use current location if available
                  onMapEvent: _onMapEvent,
                ),
                children: [
                  // Map tile layer
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    // userAgentPackageName: 'com.example.merobus',
                    // additionalOptions: const {
                    //   'attribution':
                    //       '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
                    // },
                  ),
                  if (_startLocation != null &&
                      _endLocation != null &&
                      routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          color: Colors.blue,
                          strokeWidth: 4.0,
                        ),
                      ],
                    ),
                  // Marker layer for showing locations
                  MarkerLayer(
                    markers: [
                      if (!_isRouteExpanded && _currentLocation != null)
                        Marker(
                          point: _currentLocation!,
                          width: 40.w,
                          height: 40.h,
                          child: Icon(Icons.place,
                              color: AppColors.primary, size: 30.r),
                        ),
                      if (_startLocation != null)
                        Marker(
                          point: _startLocation!,
                          width: 40.w,
                          height: 40.h,
                          child: Icon(Icons.location_on,
                              color: Colors.green, size: 30.r),
                        ),
                      if (_endLocation != null)
                        Marker(
                          point: _endLocation!,
                          width: 40.w,
                          height: 40.h,
                          child:
                              Icon(Icons.place, color: Colors.red, size: 30.r),
                        ),
                    ],
                  ),
                ],
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
                          _showCurrentLocation();
                          setState(() {
                            isSearching = false;
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
                          _showCurrentLocation();
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
                          height: _searchResults.isEmpty ? 378.h : 478.h,
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
                                if (_searchResults.isNotEmpty)
                                  Container(
                                    margin: EdgeInsets.only(top: 4.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.buttonText,
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    constraints:
                                        BoxConstraints(maxHeight: 100.h),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _searchResults.length,
                                      itemBuilder: (context, index) {
                                        final result = _searchResults[index];
                                        return ListTile(
                                          title: Text(result['display_name']),
                                          onTap: () {
                                            final lat =
                                                double.parse(result['lat']);
                                            final lng =
                                                double.parse(result['lon']);
                                            _selectRouteLocation(lat, lng);
                                          },
                                        );
                                      },
                                    ),
                                  ),
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
                                  controller: _startController,
                                  onSuffixTap: () async {
                                    try {
                                      final location =
                                          await _getCurrentLocation();
                                      _startController.text =
                                          '${location.latitude}, ${location.longitude}';
                                    } catch (e) {
                                      print(e); // Handle error appropriately
                                    }
                                  },
                                  onTap: () {
                                    setState(() {
                                      _activeController = _startController;
                                      _searchResults = [];
                                    });
                                  },
                                  onChanged: _searchPlaces,
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
                                  controller: _endController,
                                  onTap: () {
                                    setState(() {
                                      _activeController = _endController;
                                      _searchResults = [];
                                    });
                                  },
                                  onChanged: _searchPlaces,
                                ),
                                SizedBox(height: 30.h),
                                CustomButton(
                                  color: AppColors.primary,
                                  text: 'Find Now',
                                  onPressed: () {
                                    getRoutePoints();
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

  // Helper widget to build route search text fields
  Widget _buildRouteSearchField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: color),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4.r),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
        ),
        onTap: () {
          setState(() {
            _activeController = controller;
            _searchResults = [];
          });
        },
        onChanged: _searchPlaces,
      ),
    );
  }

  // Handle selection of route locations (start/end points)
  void _selectRouteLocation(double lat, double lng) {
    final position = LatLng(lat, lng);
    setState(() {
      if (_activeController == _startController) {
        _startLocation = position;
        _startController.text = _searchResults.first['display_name'];
      } else if (_activeController == _endController) {
        _endLocation = position;
        _endController.text = _searchResults.first['display_name'];
      }
      _searchResults = [];
    });
    _controller.move(position, 15.h);
  }

  // Get user's current location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are not enabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  // Center map on current location
  void _showCurrentLocation() async {
    try {
      Position position = await _getCurrentLocation();
      LatLng currentLatlng = LatLng(position.latitude, position.longitude);
      _controller.move(currentLatlng, 13.h);
      setState(() {
        _currentLocation = currentLatlng;
      });
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  // Search for places using OpenStreetMap Nominatim API
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    // Nepal's approximate bounding box
    const nepalBounds = {
      'viewbox':
          '80.0884,26.3478,88.1748,30.4477', // Nepal's min/max longitude and latitude
      'bounded': '1', // Restrict to bounding box
    };

    final url = Uri.parse('https://nominatim.openstreetmap.org/search'
        '?q=$query'
        '&format=json'
        '&limit=5'
        '&countrycodes=np' // Limit to Nepal
        '&viewbox=${nepalBounds['viewbox']}'
        '&bounded=${nepalBounds['bounded']}');

    final response = await http.get(url);
    final data = json.decode(response.body);

    setState(() {
      _searchResults = data.isNotEmpty ? data : [];
    });
  }

  // Navigate to selected search result
  void _goToSearchResult(double lat, double lng) {
    LatLng position = LatLng(lat, lng);
    _controller.move(position, 13.h);
    setState(() {
      _searchResults = [];
      _searchController.clear();
    });
  }

  // Get route points between start and end locations using OSRM API
  Future<void> getRoutePoints() async {
    if (_startLocation == null || _endLocation == null) return;

    final String url = 'https://router.project-osrm.org/route/v1/driving/'
        '${_startLocation!.longitude},${_startLocation!.latitude};'
        '${_endLocation!.longitude},${_endLocation!.latitude}'
        '?overview=full&geometries=polyline';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded['routes'] != null && decoded['routes'].isNotEmpty) {
        final String geometry = decoded['routes'][0]['geometry'];
        final List<PointLatLng> points = PolylinePoints()
            .decodePolyline(geometry)
            .map((point) => PointLatLng(point.latitude, point.longitude))
            .toList();

        setState(() {
          routePoints = points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        });

        // Calculate the bounds to include both locations
        double minLat = _startLocation!.latitude < _endLocation!.latitude
            ? _startLocation!.latitude
            : _endLocation!.latitude;
        double maxLat = _startLocation!.latitude > _endLocation!.latitude
            ? _startLocation!.latitude
            : _endLocation!.latitude;
        double minLng = _startLocation!.longitude < _endLocation!.longitude
            ? _startLocation!.longitude
            : _endLocation!.longitude;
        double maxLng = _startLocation!.longitude > _endLocation!.longitude
            ? _startLocation!.longitude
            : _endLocation!.longitude;

        // Create LatLngBounds
        final LatLngBounds bounds = LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        );

        // Calculate center and zoom level
        _controller.move(bounds.center, _getZoomForBounds(bounds));
      }
    }
  }

// Helper method to calculate an appropriate zoom level based on the bounds
  double _getZoomForBounds(LatLngBounds bounds) {
    const double minZoom = 10.0;
    const double maxZoom = 18.0;

    // Calculate the distance between the two corners (diagonal of the bounds)
    final latDiff = bounds.northEast.latitude - bounds.southWest.latitude;
    final lngDiff = bounds.northEast.longitude - bounds.southWest.longitude;
    // Approximate the distance (a simple Pythagorean theorem approach)
    final distance = sqrt(latDiff * latDiff + lngDiff * lngDiff);

    // Map the distance to a zoom level (this is an approximation)
    double zoom = 16.0 - distance * 10; // Adjust multiplier for finer control
    _currentZoom =
        zoom.clamp(minZoom, maxZoom); // Clamp between min and max zoom levels
    return _currentZoom;
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMove) {
      setState(() {
        _currentZoom = event.camera.zoom;
        _showMarker = event.camera.zoom >= 12;
      });
    }
  }
}
