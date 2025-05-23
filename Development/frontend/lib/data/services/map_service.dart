import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapService {
  Future<Position> getCurrentLocation() async {
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

  /// **2️⃣ Search for Places using OpenStreetMap (Only Nepal)**
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    const nepalBounds = {
      'viewbox': '80.0884,26.3478,88.1748,30.4477',
      'bounded': '1',
    };

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}'
      '&format=json'
      '&limit=5'
      '&countrycodes=np'
      '&viewbox=${nepalBounds['viewbox']}'
      '&bounded=${nepalBounds['bounded']}',
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'MyFlutterApp/1.0 (rai2059rabin@gmail.com)', // REQUIRED!
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception("Failed to fetch search results");
    }
  }

  /// **3️⃣ Get Route Directions using OSRM API**
  Future<List<LatLng>> getRoutePoints(LatLng start, LatLng end) async {
    final String url = 'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=polyline';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded['routes'] != null && decoded['routes'].isNotEmpty) {
        final String geometry = decoded['routes'][0]['geometry'];
        return PolylinePoints()
            .decodePolyline(geometry)
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      }
    }
    throw Exception("Failed to fetch route");
  }

  Future<LatLng?> getLatLngFromLocation(String locationName) async {
    print(locationName);
    final String baseUrl = 'https://nominatim.openstreetmap.org/search';
    final Uri url = Uri.parse(
        '$baseUrl?q=${Uri.encodeComponent(locationName)}&format=json&limit=1');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty) {
          final double latitude = double.parse(data[0]['lat']);
          final double longitude = double.parse(data[0]['lon']);
          return LatLng(latitude, longitude);
        } else {
          print('Location not found');
          return null;
        }
      } else {
        print('Failed to fetch location: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching location: $e');
      return null;
    }
  }

  
}
