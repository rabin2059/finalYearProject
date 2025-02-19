import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/map_model.dart';

class MapService {
  static const String _nominatimBaseUrl = "https://nominatim.openstreetmap.org";
  static const String _openRouteServiceBaseUrl =
      "https://api.openrouteservice.org/v2/directions/driving-car";
  static const String _apiKey =
      "5b3ce3597851110001cf6248f5bd762aa79f405db3667d88c05eb6bb";

  /// **1. Reverse Geocoding: Get Address from LatLng (Only Nepal)**
  Future<LocationModel> getReverseGeocode(double lat, double lng) async {
    final url =
        "$_nominatimBaseUrl/reverse?lat=$lat&lon=$lng&format=json&countrycodes=np";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return LocationModel.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to fetch address");
    }
  }

  /// **2. Geocoding: Get LatLng from Address (Only Nepal)**
  Future<LocationModel> getCoordinatesFromAddress(String address) async {
    final url =
        "$_nominatimBaseUrl/search?q=${Uri.encodeComponent(address)}&format=json&limit=1&countrycodes=np";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> results = json.decode(response.body);
      if (results.isNotEmpty) {
        return LocationModel.fromJson(results[0]);
      } else {
        throw Exception("No location found in Nepal");
      }
    } else {
      throw Exception("Failed to fetch coordinates");
    }
  }

  /// **3. Route Directions (No Nepal Restriction Needed)**
  Future<RouteModel> getRoute(LocationModel start, LocationModel end) async {
    final url =
        "$_openRouteServiceBaseUrl?api_key=$_apiKey&start=${start.longitude},${start.latitude}&end=${end.longitude},${end.latitude}";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return RouteModel.fromJson(json.decode(response.body));
    } else {
      throw Exception("Failed to fetch route");
    }
  }

  /// **4. Search Autocomplete (Only Nepal)**
  Future<List<LocationModel>> searchPlaces(String query) async {
    final url =
        "$_nominatimBaseUrl/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&countrycodes=np";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> results = json.decode(response.body);
      return results.map((json) => LocationModel.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch search results");
    }
  }
}