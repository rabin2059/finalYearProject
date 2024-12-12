import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/bus.dart';
import '../../widgets/seat_layout.dart';

class BusDetailsScreen extends StatefulWidget {
  final Bus bus;
  final List<LatLng> routePoints;
  final LatLng userLocation;

  const BusDetailsScreen({
    Key? key,
    required this.bus,
    required this.routePoints,
    required this.userLocation,
  }) : super(key: key);

  @override
  _BusDetailsScreenState createState() => _BusDetailsScreenState();
}

class _BusDetailsScreenState extends State<BusDetailsScreen> {
  final MapController mapController = MapController();
  bool showSeatLayout = false;

  // Mock data for seats
  final List<Map<String, dynamic>> seats = List.generate(
    32,
    (index) => {
      'id': 'S${index + 1}',
      'isAvailable': index % 3 != 0, // Some seats are booked
      'price': 25.0, // Price in NPR
    },
  );

  String _calculateETA() {
    // Calculate distance and time based on route points
    // This is a simplified calculation
    double totalDistance = 0;
    int userPointIndex = -1;
    int busPointIndex = -1;

    // Find user and bus positions in the route
    for (int i = 0; i < widget.routePoints.length; i++) {
      if (userPointIndex == -1 && 
          _isNearPoint(widget.userLocation, widget.routePoints[i])) {
        userPointIndex = i;
      }
      if (busPointIndex == -1 && 
          _isNearPoint(LatLng(widget.bus.latitude, widget.bus.longitude), 
          widget.routePoints[i])) {
        busPointIndex = i;
      }
    }

    if (userPointIndex == -1 || busPointIndex == -1 || userPointIndex <= busPointIndex) {
      return 'Bus has passed your location';
    }

    // Calculate remaining distance
    for (int i = busPointIndex; i < userPointIndex; i++) {
      totalDistance += _calculateDistance(
        widget.routePoints[i],
        widget.routePoints[i + 1],
      );
    }

    // Assume average speed of 30 km/h in city
    int minutes = (totalDistance / 500).round(); // Simplified calculation
    return '$minutes minutes';
  }

  bool _isNearPoint(LatLng point1, LatLng point2) {
    const double threshold = 0.001; // About 100 meters
    return (point1.latitude - point2.latitude).abs() < threshold &&
        (point1.longitude - point2.longitude).abs() < threshold;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    // Simple distance calculation (you can use your existing calculation)
    return (point1.latitude - point2.latitude).abs() +
        (point1.longitude - point2.longitude).abs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bus ${widget.bus.busNumber}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: LatLng(widget.bus.latitude, widget.bus.longitude),
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.routePoints,
                        color: Colors.blue,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(widget.bus.latitude, widget.bus.longitude),
                        width: 40,
                        height: 40,
                        child: Icon(Icons.directions_bus, color: Colors.blue),
                      ),
                      Marker(
                        point: widget.userLocation,
                        width: 40,
                        height: 40,
                        child: Icon(Icons.location_on, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bus Details',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow('Route', widget.bus.routeName),
                  _buildInfoRow('Driver', widget.bus.driverName),
                  _buildInfoRow('Status', widget.bus.status),
                  _buildInfoRow('Next Stop', widget.bus.nextStop),
                  _buildInfoRow('ETA to Your Location', _calculateETA()),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showSeatLayout = !showSeatLayout;
                      });
                    },
                    child: Text(showSeatLayout ? 'Hide Seats' : 'Book Seats'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                  if (showSeatLayout) ...[
                    SizedBox(height: 16),
                    SeatLayout(
                      seats: seats,
                      onSeatSelected: (seatId) {
                        // Handle seat selection
                        _showBookingDialog(seatId);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(String seatId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seat: $seatId'),
            Text('Price: NPR 25.0'),
            SizedBox(height: 16),
            Text('Would you like to proceed with booking?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle booking confirmation
              Navigator.pop(context);
              _showBookingConfirmation();
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showBookingConfirmation() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking confirmed! Check your email for details.'),
        backgroundColor: Colors.green,
      ),
    );
  }
} 