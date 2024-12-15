// Import required packages
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:merobus/Components/AppColors.dart';
import 'package:http/http.dart' as http;

// Main map screen widget
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
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
  bool _isSearching = false;
  bool _isRouteExpanded = false;

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
      body: Stack(
        children: [
          // Main map widget
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialZoom: 13.h,
              initialCenter: _currentLocation ??
                  const LatLng(
                      27.7172, 85.3240), // Use current location if available
              onTap: (_, __) {
                setState(() => _isSearching = false);
              },
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
                      child: Icon(Icons.place, color: Colors.red, size: 30.r),
                    ),
                ],
              ),
            ],
          ),

          // Search bar - only visible when route is not expanded
          if (!_isRouteExpanded)
            Positioned(
              top: 48.h,
              left: 15.w,
              right: 15.w,
              child: Column(
                children: [
                  // Search text field
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Location',
                      filled: true,
                      fillColor: AppColors.buttonText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50.r),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textPrimary),
                      suffixIcon: _isSearching
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _isSearching = false;
                                  _searchResults = [];
                                });
                              },
                              icon: const Icon(Icons.clear))
                          : null,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    onTap: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                  ),
                  // Search results list
                  if (_isSearching && _searchResults.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.buttonText,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      constraints: BoxConstraints(maxHeight: 200.h),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            title: Text(result['display_name']),
                            onTap: () {
                              final lat = double.parse(result['lat']);
                              final lng = double.parse(result['lon']);
                              _goToSearchResult(lat, lng);
                            },
                          );
                        },
                      ),
                    )
                ],
              ),
            ),

          // Expandable route search panel
          if (_isRouteExpanded)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    topRight: Radius.circular(20.r),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Panel header
                    Padding(
                      padding: EdgeInsets.all(16.r),
                      child: Text(
                        'Search your Route',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.r),
                      child: Column(
                        children: [
                          // From location field
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: TextField(
                              controller: _startController,
                              decoration: InputDecoration(
                                hintText: 'From location',
                                border: InputBorder.none,
                                prefixIcon: const Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.grey),
                                suffixIcon: const Icon(Icons.my_location,
                                    color: Colors.green),
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16.r),
                              ),
                              onTap: () {
                                setState(() {
                                  _activeController = _startController;
                                  _searchResults = [];
                                });
                              },
                              onChanged: _searchPlaces,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // To location field
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: TextField(
                              controller: _endController,
                              decoration: InputDecoration(
                                hintText: 'To location',
                                border: InputBorder.none,
                                prefixIcon: const Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.grey),
                                suffixIcon:
                                    const Icon(Icons.map, color: Colors.grey),
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16.r),
                              ),
                              onTap: () {
                                setState(() {
                                  _activeController = _endController;
                                  _searchResults = [];
                                });
                              },
                              onChanged: _searchPlaces,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          // Go To button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_startLocation != null && _endLocation != null) {
                                  // Get route points first
                                  await getRoutePoints();
                                  
                                  // Move map to show both markers
                                  final bounds = LatLngBounds.fromPoints([
                                    _startLocation!,
                                    _endLocation!,
                                  ]);
                                  _controller.move(
                                    bounds.center,
                                    _controller.camera.zoom ?? 13.h,
                                  );

                                  setState(() {
                                    _isRouteExpanded = false; // Hide the route panel
                                  });
                                } else {
                                  // Show error if locations aren't selected
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please select both start and end locations'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8BC34A),
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: Text(
                                'Go To',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
                    // Search results list
                    if (_searchResults.isNotEmpty)
                      Container(
                        constraints: BoxConstraints(maxHeight: 200.h),
                        color: Colors.white,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on_outlined),
                              title: Text(result['display_name']),
                              onTap: () {
                                final lat = double.parse(result['lat']);
                                final lng = double.parse(result['lon']);
                                _selectRouteLocation(lat, lng);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Back button - only visible when route is expanded
          if (_isRouteExpanded)
            Positioned(
              top: 48.h,
              left: 15.w,
              child: FloatingActionButton(
                heroTag: "back",
                mini: true,
                backgroundColor: Colors.white,
                elevation: 2,
                onPressed: () {
                  setState(() {
                    _isRouteExpanded = false;
                    _startLocation = null;
                    _endLocation = null;
                    _startController.clear();
                    _endController.clear();
                    _searchResults = [];
                  });
                },
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),

          // Action buttons - only visible when route is not expanded
          if (!_isRouteExpanded)
            Positioned(
              bottom: 20.h,
              right: 20.w,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current location button
                  FloatingActionButton(
                    heroTag: "location",
                    backgroundColor: AppColors.buttonText,
                    foregroundColor: AppColors.primary,
                    onPressed: _showCurrentLocation,
                    child: Icon(Icons.location_searching_rounded, size: 30.r),
                  ),
                  SizedBox(height: 10.h),
                  // Route search toggle button
                  FloatingActionButton(
                    heroTag: "goto",
                    backgroundColor: const Color(0xFF8BC34A),
                    foregroundColor: Colors.white,
                    onPressed: () {
                      setState(() {
                        _isRouteExpanded = !_isRouteExpanded;
                        if (!_isRouteExpanded) {
                          _startLocation = null;
                          _endLocation = null;
                          _startController.clear();
                          _endController.clear();
                          _searchResults = [];
                        }
                      });
                    },
                    child: Icon(
                      _isRouteExpanded ? Icons.close : Icons.directions,
                      size: 30.r,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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
        _isSearching = false;
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
      }
    }
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
