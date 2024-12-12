import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:math' show pi, sin, cos, sqrt, atan2;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/map_provider.dart';
import '../../widgets/bus_details_card.dart';
import '../../models/bus.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _startLocationController = TextEditingController();
  final TextEditingController _endLocationController = TextEditingController();
  MapController mapController = MapController();
  LatLng? startPoint;
  LatLng? endPoint;
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  double _currentZoom = 13.0;
  bool _showMarker = true;
  TextEditingController? _activeController;
  List<LatLng> routePoints = [];
  List<LatLng> dynamicBusLocations = [];
  final int numberOfBuses = 3; // Number of buses to show on route
  bool _isLoadingLocation = true;
  String? _locationError;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      context.read<MapProvider>().simulateBusMovement();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permissions are denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permissions are permanently denied';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        startPoint = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Get address for the location
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}'),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          _startLocationController.text = decoded['display_name'];
        });
      }

      // Move map to current location
      mapController.move(startPoint!, 15.0);

    } catch (e) {
      setState(() {
        _locationError = e.toString();
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> getSuggestions(String query) async {
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final response = await http.get(
      Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=5'),
    );

    if (response.statusCode == 200) {
      final List results = json.decode(response.body);
      setState(() {
        _suggestions = results.map((result) => {
          'display_name': result['display_name'],
          'lat': double.parse(result['lat']),
          'lon': double.parse(result['lon']),
        }).toList();
        _showSuggestions = true;
      });
    }
  }

  Future<void> getRoutePoints() async {
    if (startPoint == null || endPoint == null) return;

    final String url = 'https://router.project-osrm.org/route/v1/driving/'
        '${startPoint!.longitude},${startPoint!.latitude};'
        '${endPoint!.longitude},${endPoint!.latitude}'
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
        
        // Initialize buses on the new route
        context.read<MapProvider>().updateRoute(routePoints);
        
        // Calculate bus locations after getting route points
        calculateBusLocations();
      }
    }
  }

  void selectLocation(Map<String, dynamic> location) {
    final selectedPoint = LatLng(location['lat'], location['lon']);
    
    setState(() {
      if (_activeController == _startLocationController) {
        startPoint = selectedPoint;
        _startLocationController.text = location['display_name'];
      } else {
        endPoint = selectedPoint;
        _endLocationController.text = location['display_name'];
      }
      _showSuggestions = false;
    });

    if (startPoint != null && endPoint != null) {
      getRoutePoints();
      context.read<MapProvider>().updateRoute([startPoint!, endPoint!]);
      mapController.fitBounds(
        LatLngBounds.fromPoints([startPoint!, endPoint!]),
        options: const FitBoundsOptions(padding: EdgeInsets.all(50.0)),
      );
    } else {
      mapController.move(selectedPoint, 13.0);
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

  Widget buildBusMarkerWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Icon(
          Icons.directions_bus,
          color: Colors.blue,
          size: 20,
        ),
      ),
    );
  }

  void calculateBusLocations() {
    if (routePoints.isEmpty) return;

    setState(() {
      dynamicBusLocations = [];
      
      // Calculate total route distance
      double totalDistance = 0;
      for (int i = 0; i < routePoints.length - 1; i++) {
        totalDistance += calculateDistance(routePoints[i], routePoints[i + 1]);
      }

      // Place buses at equal intervals
      for (int busIndex = 0; busIndex < numberOfBuses; busIndex++) {
        double targetDistance = (totalDistance * (busIndex + 1)) / (numberOfBuses + 1);
        double currentDistance = 0;
        
        for (int i = 0; i < routePoints.length - 1; i++) {
          double segmentDistance = calculateDistance(routePoints[i], routePoints[i + 1]);
          if (currentDistance + segmentDistance >= targetDistance) {
            double ratio = (targetDistance - currentDistance) / segmentDistance;
            LatLng busLocation = interpolatePoint(routePoints[i], routePoints[i + 1], ratio);
            dynamicBusLocations.add(busLocation);
            break;
          }
          currentDistance += segmentDistance;
        }
      }
    });
  }

  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    double lat1 = point1.latitude * pi / 180;
    double lat2 = point2.latitude * pi / 180;
    double dLat = (point2.latitude - point1.latitude) * pi / 180;
    double dLon = (point2.longitude - point1.longitude) * pi / 180;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  LatLng interpolatePoint(LatLng start, LatLng end, double ratio) {
    return LatLng(
      start.latitude + (end.latitude - start.latitude) * ratio,
      start.longitude + (end.longitude - start.longitude) * ratio,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Route Planner")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _startLocationController,
                  decoration: InputDecoration(
                    hintText: _isLoadingLocation 
                      ? 'Getting your location...' 
                      : _locationError ?? 'Start location...',
                    prefixIcon: Icon(
                      Icons.location_on,
                      color: _locationError != null ? Colors.red : Colors.green,
                    ),
                    suffixIcon: _isLoadingLocation 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : IconButton(
                          icon: Icon(Icons.my_location),
                          onPressed: _getCurrentLocation,
                        ),
                    border: OutlineInputBorder(),
                  ),
                  onTap: () {
                    setState(() {
                      _activeController = _startLocationController;
                    });
                  },
                  onChanged: (value) {
                    getSuggestions(value);
                  },
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _endLocationController,
                  decoration: InputDecoration(
                    hintText: 'End location...',
                    prefixIcon: Icon(Icons.location_on, color: Colors.red),
                    border: OutlineInputBorder(),
                  ),
                  onTap: () {
                    setState(() {
                      _activeController = _endLocationController;
                    });
                  },
                  onChanged: (value) {
                    getSuggestions(value);
                  },
                ),
                if (_showSuggestions && _suggestions.isNotEmpty)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            _suggestions[index]['display_name'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            selectLocation(_suggestions[index]);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: LatLng(27.7172, 85.3240), // Kathmandu
                    initialZoom: 13.0,
                    minZoom: 3,
                    maxZoom: 18,
                    onTap: (_, __) {
                      setState(() => _showSuggestions = false);
                    },
                    onMapEvent: _onMapEvent,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.merobus',
                    ),
                    if (startPoint != null && endPoint != null && routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            color: Colors.blue,
                            strokeWidth: 4.0,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (startPoint != null)
                          Marker(
                            point: startPoint!,
                            width: 40,
                            height: 40,
                            child: Icon(Icons.location_on, color: Colors.green),
                          ),
                        if (endPoint != null)
                          Marker(
                            point: endPoint!,
                            width: 40,
                            height: 40,
                            child: Icon(Icons.location_on, color: Colors.red),
                          ),
                        ...context.watch<MapProvider>().buses.map(
                          (bus) => Marker(
                            point: LatLng(bus.latitude, bus.longitude),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/bus-details',
                                  arguments: {
                                    'bus': bus,
                                    'routePoints': routePoints,
                                    'userLocation': startPoint!,
                                  },
                                );
                              },
                              child: buildBusMarkerWidget(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: "zoom_in",
                        mini: true,
                        onPressed: () {
                          final newZoom = mapController.camera.zoom + 1;
                          if (newZoom <= 18) {
                            mapController.move(
                              mapController.camera.center,
                              newZoom,
                            );
                          }
                        },
                        child: Icon(Icons.add),
                      ),
                      SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: "zoom_out",
                        mini: true,
                        onPressed: () {
                          final newZoom = mapController.camera.zoom - 1;
                          if (newZoom >= 3) {
                            mapController.move(
                              mapController.camera.center,
                              newZoom,
                            );
                          }
                        },
                        child: Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text('Start Point'),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('End Point'),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            buildBusMarkerWidget(),
                            SizedBox(width: 8),
                            Text('Bus Location'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FitBoundsOptions {
  const FitBoundsOptions({required EdgeInsets padding});
}

extension on MapController {
  void fitBounds(LatLngBounds latLngBounds, {required options}) {}
}

void main() => runApp(MaterialApp(home: MapScreen()));