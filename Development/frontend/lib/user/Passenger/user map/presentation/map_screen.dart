import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/core/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../components/AppColors.dart';
import '../../../../components/CustomButton.dart';
import '../../../../data/services/socket_service.dart';
import '../../../map/providers/map_provider.dart';
import 'package:http/http.dart' as http;

class MapScreens extends ConsumerStatefulWidget {
  const MapScreens({super.key});

  @override
  ConsumerState<MapScreens> createState() => _MapScreensState();
}

class _MapScreensState extends ConsumerState<MapScreens> {
  final MapController _controller = MapController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  TextEditingController? _activeController;

  bool isSearching = true;
  double _currentZoom = 13.0;
  bool _showMarker = true;

  Timer? _debounce; // Timer for debouncing search requests

  List<String> _startSuggestions = [];
  List<String> _endSuggestions = [];
  bool _showStartSuggestions = false;
  bool _showEndSuggestions = false;

  final List<Marker> _vehicleMarkers = [];
  bool _showDriverInfo = false;
  Map<String, dynamic>? _selectedDriver;
  String? _selectedVehicleId;
  List<Map<String, dynamic>> _filteredVehicles = [];

  LatLng? _startCoordinates;
  LatLng? _endCoordinates;
  List<dynamic> _vehicles = [];
  bool _mounted = true;

  // Tracks if vehicles have been loaded
  bool _vehiclesLoaded = false;

  // Map to track vehicle locations by vehicleId
  final Map<String, LatLng> _vehicleLocations = {};

  // Reference to SocketService
  SocketService? _socketService;

  // Control vehicle list visibility
  bool _showVehicleList = false;
  final Set<String> _activeSocketUsers = {};

  @override
  void initState() {
    super.initState();
    _initSocketService();
  }

  void _initSocketService() {
    _socketService = SocketService(baseUrl: socketBaseUrl);
    _socketService?.connect("user-${DateTime.now().millisecondsSinceEpoch}");
 
    _socketService?.onVehicleLocation = (vehicleId, lat, lng) {
      if (!mounted) return;
      setState(() {
        _vehicleLocations[vehicleId] = LatLng(lat, lng);
      });
      _updateVehicleMarkers();
    };
    _socketService?.onActiveBusesReceived.addListener(() {
      if (!mounted) return;
      setState(() {
        _activeSocketUsers.clear();
        for (var driverId in _socketService!.onActiveBusesReceived.value) {
          _activeSocketUsers.add('driver-$driverId');
        }
      });
    });
    _socketService?.requestActiveBuses();
  }

  void _clearMapState() {
    final mapNotifier = ref.read(mapProvider.notifier);
    mapNotifier.clearRoute();

    // Reset local state
    setState(() {
      _startController.clear();
      _endController.clear();
      _startCoordinates = null;
      _endCoordinates = null;
      _vehicleMarkers.clear();
      _vehicles.clear();
      _filteredVehicles.clear();
      _vehicleLocations.clear();
      _selectedDriver = null;
      _selectedVehicleId = null;
      _showDriverInfo = false;
      _showVehicleList = false;
      _vehiclesLoaded = false;
      isSearching = true;
    });

    // Reset map to default position
    _controller.move(
        ref.read(mapProvider).userLocation ?? const LatLng(27.7172, 85.3240),
        _currentZoom = 13.0);
  }

  void _updateVehicleMarkers() {
    _vehicleMarkers.clear();

    // Only add a marker for the selected vehicle
    if (_selectedVehicleId != null &&
        _vehicleLocations.containsKey(_selectedVehicleId)) {
      // Find the vehicle info for this vehicleId
      final vehicle = _vehicles.firstWhere(
          (v) => v['vehicleId'].toString() == _selectedVehicleId,
          orElse: () => {
                'vehicleModel': 'Unknown',
                'vehicleType': 'Vehicle',
                'driver': {'name': 'Unknown'}
              });

      final location = _vehicleLocations[_selectedVehicleId]!;

      _vehicleMarkers.add(
        Marker(
          width: 40.w,
          height: 40.h,
          point: location,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final details = await _calculateDistanceAndTime(location);
                setState(() {
                  _selectedDriver = {
                    'name': vehicle['driver']['name'] ?? 'Unknown Driver',
                    'vehicleInfo':
                        '${vehicle['vehicleModel']} - ${vehicle['vehicleType']} (ID: $_selectedVehicleId)',
                    'rating': 4.5,
                  'distance': details['distance'] ?? 'Unknown',
                    'duration': details['duration'] ?? '',
                  };
                  _showDriverInfo = !_showDriverInfo;
                });
              },
              child: Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Center(
                  child: Icon(
                    Icons.directions_bus,
                    color: AppColors.primary,
                    size: 25,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    setState(() {});
  }

  void _selectVehicle(dynamic vehicle) {
    final vehicleId = vehicle['vehicleId'].toString();

    if (vehicle['hasActiveBuses'] == true &&
        vehicle['activeBuses'] != null &&
        vehicle['activeBuses'].isNotEmpty) {
      final busData = vehicle['activeBuses'][0];
      final location = LatLng(
        busData['location']['lat'],
        busData['location']['lng'],
      );

      setState(() {
        _selectedVehicleId = vehicleId;
        _vehicleLocations[vehicleId] = location;
        _selectedDriver = {
          'name': vehicle['driver']['name'] ?? 'Unknown Driver',
          'vehicleInfo':
              '${vehicle['vehicleModel']} - ${vehicle['vehicleType']} (ID: $vehicleId)',
          'rating': 4.5,
          'distance': 'On route',
        };
        _showVehicleList = false; // Close vehicle list when selected
        // _showDriverInfo = true; // Removed to prevent immediate driver info display
      });
      
      final userLocation = ref.read(mapProvider).userLocation;
      if (userLocation != null) {
      final bounds = LatLngBounds(ref.read(mapProvider).userLocation!, location);
        bounds.extend(userLocation);
        bounds.extend(location);
        final center = LatLng(
          (bounds.north + bounds.south) / 2,
          (bounds.east + bounds.west) / 2,
        );
        final zoom = _getZoomForBounds(bounds);
        _controller.move(center, zoom);
      }

      _updateVehicleMarkers();
      _controller.move(location, 15);
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _startController.dispose();
    _endController.dispose();
    _debounce?.cancel();
    _socketService?.dispose();

    // Delay clearing the map if needed, or remove this if handled inside the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(mapProvider.notifier).clearRoute();
      }
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final mapNotifier = ref.read(mapProvider.notifier);
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        _clearMapState();
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialZoom: _currentZoom,
                initialCenter: mapState.userLocation ??
                    const LatLng(27.7172, 85.3240), // Default Kathmandu
                onMapEvent: (event) => _onMapEvent(event),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                if (_showMarker && mapState.userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40.w,
                        height: 40.h,
                        point: mapState.userLocation!,
                        child: const Icon(Icons.location_pin,
                            color: Colors.red, size: 30),
                      )
                    ],
                  ),
                if (mapState.route != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: mapState.route!.routePoints
                            .map((e) => LatLng(e.latitude, e.longitude))
                            .toList(),
                        strokeWidth: 4.0,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    ..._vehicleMarkers,
                    if (mapState.route != null) ...[
                      // Start point marker
                      Marker(
                        width: 40.w,
                        height: 40.h,
                        point: LatLng(
                          mapState.route!.routePoints.first.latitude,
                          mapState.route!.routePoints.first.longitude,
                        ),
                        child: const Icon(Icons.location_on,
                            color: Colors.green, size: 30),
                      ),
                      // End point marker
                      Marker(
                        width: 40.w,
                        height: 40.h,
                        point: LatLng(
                          mapState.route!.routePoints.last.latitude,
                          mapState.route!.routePoints.last.longitude,
                        ),
                        child: const Icon(Icons.location_on,
                            color: Colors.red, size: 30),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // **Back Button**
            Positioned(
              top: 50.h,
              left: 15.w,
              child: FloatingActionButton(
                heroTag: "back",
                mini: true,
                backgroundColor: Colors.white,
                elevation: 2,
                onPressed: () {
                  _clearMapState();
                  Navigator.pop(context);
                },
                child: Icon(Icons.arrow_back, size: 25.r),
              ),
            ),

            // **Search UI**
            isSearching
                ? Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildSearchContainer(mapNotifier),
                  )
                : !_showVehicleList // Only show these buttons when vehicle list is hidden
                    ? Stack(
                        children: [
                          // Search Button
                          Positioned(
                            bottom: 30.h,
                            right: 15.w,
                            child: FloatingActionButton(
                              heroTag: "search",
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              onPressed: () {
                                setState(() {
                                  isSearching = true;
                                  _showVehicleList = false;
                                });
                              },
                              child: Icon(Icons.search, size: 25.r),
                            ),
                          ),

                          if (_vehiclesLoaded || !_showDriverInfo)
                            Positioned(
                              bottom: 90.h,
                              right: 15.w,
                              child: FloatingActionButton(
                                heroTag: "vehicleListToggle",
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                onPressed: () {
                                  setState(() {
                                    _showVehicleList = true;
                                  });
                                },
                                child: Icon(Icons.directions_bus, size: 20.r),
                              ),
                            ),
                        ],
                      )
                    : const SizedBox(),

            if (!isSearching && _showVehicleList && _vehicles.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: screenHeight * 0.5, // Half the screen height
                child: GestureDetector(
                  onVerticalDragEnd: (details) {
                    // If swipe down with significant velocity
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! > 300) {
                      setState(() {
                        _showVehicleList = false;
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20.r)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, -2),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        // Drag indicator at top
                        Container(
                          width: 40.w,
                          height: 5.h,
                          margin: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2.5.r),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Available Vehicles",
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.keyboard_arrow_down),
                                onPressed: () {
                                  setState(() {
                                    _showVehicleList = false;
                                  });
                                },
                              )
                            ],
                          ),
                        ),
                        Divider(height: 1),
                        // Expanded list to fill the container
                        Expanded(
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            itemCount: _filteredVehicles.length,
                            separatorBuilder: (context, index) =>
                                Divider(height: 1),
                            itemBuilder: (context, index) {
                              final vehicle = _filteredVehicles[index];
                              final isLive = vehicle['hasActiveBuses'] == true;
                              final vehicleId = vehicle['vehicleId'].toString();
                              final isSelected =
                                  vehicleId == _selectedVehicleId;

                              return InkWell(
                                onTap: isLive
                                    ? () => _selectVehicle(vehicle)
                                    : null,
                                child: Container(
                                  color: isSelected
                                      ? Colors.blue.withOpacity(0.1)
                                      : null,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 8.h, horizontal: 16.w),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isLive
                                          ? AppColors.primary
                                          : Colors.grey,
                                      child: Icon(
                                        Icons.directions_bus,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      '${vehicle['vehicleModel']} (${vehicle['vehicleType']})',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                        'Driver: ${vehicle['driver']['name']}'),
                                    trailing: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isLive
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(20.r),
                                      ),
                                      child: Text(
                                        isLive ? 'ACTIVE' : 'INACTIVE',
                                        style: TextStyle(
                                          color: isLive
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
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
              ),

            // Driver Info Sheet
            if (_showDriverInfo && _selectedDriver != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta! > 10) {
                      setState(() {
                        _showDriverInfo = false;
                      });
                    }
                  },
                  child: _buildDriverInfoSheet(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// **Handles Search UI**
  Widget _buildSearchContainer(MapNotifier mapNotifier) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, -3))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchField(
              controller: _startController,
              hint: "From Location",
              onSearch: (query) => _debouncedSearch(query, mapNotifier, true)),
          _showStartSuggestions
              ? _buildSuggestions(_startSuggestions, true)
              : const SizedBox(),
          SizedBox(height: 10.h),
          _buildSearchField(
              controller: _endController,
              hint: "To Location",
              onSearch: (query) => _debouncedSearch(query, mapNotifier, false)),
          _showEndSuggestions
              ? _buildSuggestions(_endSuggestions, false)
              : const SizedBox(),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: CustomButton(
              text: "Find Now",
              color: AppColors.primary,
              onPressed: () async {
                await _handleFindNowPress(mapNotifier);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// **Handles Search Suggestions Display**
  Widget _buildSuggestions(List<String> suggestions, bool isStart) {
    return Container(
      height: 150.h,
      margin: EdgeInsets.symmetric(vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return ListTile(
              title: Text(suggestions[index]),
              onTap: () async {
                if (!mounted) return; // Safeguard
                final selectedLocation = suggestions[index];

                setState(() {
                  if (isStart) {
                    _startController.text = selectedLocation;
                    _showStartSuggestions = false;
                  } else {
                    _endController.text = selectedLocation;
                    _showEndSuggestions = false;
                  }
                });
                if (!mounted) return;
              });
        },
      ),
    );
  }

  /// **Handles Search Suggestions Display**
  Widget _buildSearchField(
      {required TextEditingController controller,
      required String hint,
      required Function(String) onSearch}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
      ),
      onChanged: onSearch,
    );
  }

  void _debouncedSearch(String query, MapNotifier mapNotifier, bool isStart) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!_mounted || !mounted) return; // 👈 safeguard

      if (query.isNotEmpty) {
        await mapNotifier.searchPlaces(query);
        if (!_mounted || !mounted) return;

        final searchResults = ref.read(mapProvider).searchResults;

        setState(() {
          if (isStart) {
            _startSuggestions =
                searchResults.map((l) => l.address ?? "").toList();
            _showStartSuggestions = true;
          } else {
            _endSuggestions =
                searchResults.map((l) => l.address ?? "").toList();
            _showEndSuggestions = true;
          }
        });
      } else {
        if (!_mounted || !mounted) return;
        setState(() {
          if (isStart) {
            _startSuggestions.clear();
            _showStartSuggestions = false;
          } else {
            _endSuggestions.clear();
            _showEndSuggestions = false;
          }
        });
      }
    });
  }

  double _getZoomForBounds(LatLngBounds bounds) {
    const double minZoom = 10.0;
    const double maxZoom = 18.0;

    // Calculate the distance between two points
    final latDiff = bounds.northEast.latitude - bounds.southWest.latitude;
    final lngDiff = bounds.northEast.longitude - bounds.southWest.longitude;
    final distance = sqrt(latDiff * latDiff + lngDiff * lngDiff);

    double zoom = 16.0 - distance * 10; // Approximate zoom calculation
    _currentZoom = zoom.clamp(minZoom, maxZoom);
    return _currentZoom;
  }

  /// **Handles Map Zoom Events**
  void _onMapEvent(MapEvent event) {
    if (event is MapEventMove) {
      setState(() {
        _currentZoom = _controller.camera.zoom;
        _showMarker = _currentZoom >= 12; // Show markers when zoom level is 12 or higher
      });
    }
  }

  Future<Map<String, String>> _calculateDistanceAndTime(LatLng driverLocation) async {
    final userLocation = ref.read(mapProvider).userLocation;
    if (userLocation == null) return {'distance': 'Unknown', 'duration': ''};

    final distance = Distance().as(LengthUnit.Kilometer, userLocation, driverLocation);
    String distanceStr = "${distance.toStringAsFixed(1)} km";

    // Approximate time assuming 30km/h average speed
    final timeInMinutes = (distance / 30) * 60;
    String timeStr = "${timeInMinutes.round()} mins";

    if (userLocation.latitude > driverLocation.latitude ||
        userLocation.longitude > driverLocation.longitude) {
      return {'distance': distanceStr, 'duration': timeStr};
    } else {
      return {'distance': distanceStr, 'duration': ''}; // ahead
    }
  }

  Future<void> _handleFindNowPress(MapNotifier mapNotifier) async {
    final startCoordinates =
        await mapNotifier.getCoordinatesFromAddress(_startController.text);
    final endCoordinates =
        await mapNotifier.getCoordinatesFromAddress(_endController.text);
    if (startCoordinates == null || endCoordinates == null) return;

    try {
      final url = Uri.parse(
          "$apiBaseUrl/getVehiclesRoute?startLat=${startCoordinates.latitude}&startLng=${startCoordinates.longitude}&endLat=${endCoordinates.latitude}&endLng=${endCoordinates.longitude}");

      final response = await http.get(url);
      _socketService?.requestActiveBuses();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final allVehicles =
            List<Map<String, dynamic>>.from(data['vehicles'] ?? []);

        _vehicles = allVehicles;

        _filteredVehicles =
            allVehicles; // show all vehicles, active and inactive

        _vehicleMarkers.clear();

        if (!mounted) return;
        setState(() {
          _showVehicleList = true;
          _vehiclesLoaded = true;
          isSearching = false;
        });
      }
    } catch (e) {
      print('Error fetching vehicles: $e');
    }
  }

  Widget _buildDriverInfoSheet() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40.w,
            height: 5.h,
            margin: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.5.r),
            ),
          ),
          // Content
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30.r,
                          backgroundColor: Colors.grey[200],
                          child: ClipOval(
                            child: Icon(
                              Icons.person,
                              size: 30.r,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedDriver!['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                _selectedDriver!['vehicleInfo'] ?? '',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Icon(Icons.star,
                                      color: Colors.amber, size: 16.r),
                                  SizedBox(width: 4.w),
                                  Text(
                                    '${_selectedDriver!['rating']}',
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                  SizedBox(width: 16.w),
                                  Icon(Icons.location_on,
                                      color: Colors.grey, size: 16.r),
                                  SizedBox(width: 4.w),
                                  Text(
                                    _selectedDriver!['duration'] != null && _selectedDriver!['duration'].toString().isNotEmpty
                                        ? '${_selectedDriver!['distance']} • ETA: ${_selectedDriver!['duration']}'
                                        : '${_selectedDriver!['distance']}',
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    CustomButton(
                      text: "Book Now",
                      color: AppColors.primary,
                      onPressed: () {
                        context.pushNamed('/book', pathParameters: {
                          'id': _selectedVehicleId ?? '',
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
