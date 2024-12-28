import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Fetch the user's current location
Future<LatLng> getCurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    await Geolocator.openLocationSettings();
    throw Exception("Location services are disabled.");
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception("Location permission denied.");
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception("Location permission denied forever.");
  }

  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
  return LatLng(position.latitude, position.longitude);
}

/// Fetch place suggestions based on the input string
Future<List<String>> fetchPlaceSuggestions(String input, String apiKey) async {
  final String url =
      "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey";
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final predictions = data['predictions'] as List;
    return predictions.map((prediction) => prediction['description'] as String).toList();
  } else {
    throw Exception('Failed to load suggestions');
  }
}

/// Fetch coordinates from an address
Future<LatLng> fetchCoordinatesFromAddress(
    String address, String apiKey) async {
  const String baseUrl = "https://maps.googleapis.com/maps/api/geocode/json";
  final String requestUrl = "$baseUrl?address=$address&key=$apiKey";

  try {
    final response = await http.get(Uri.parse(requestUrl));
    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['results'].isNotEmpty) {
      double lat = data['results'][0]['geometry']['location']['lat'];
      double lng = data['results'][0]['geometry']['location']['lng'];
      return LatLng(lat, lng);
    } else {
      throw Exception("Failed to load coordinates.");
    }
  } catch (e) {
    print("Error fetching coordinates: ${e.toString()}");
    return const LatLng(0.0, 0.0); // Return a default value instead of null
  }
}

/// Fetch address from coordinates
Future<String> fetchAddressFromCoordinates(
    LatLng coordinates, String apiKey) async {
  const String baseUrl = "https://maps.googleapis.com/maps/api/geocode/json";
  final String requestUrl =
      "$baseUrl?latlng=${coordinates.latitude},${coordinates.longitude}&key=$apiKey";

  try {
    final response = await http.get(Uri.parse(requestUrl));
    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['results'].isNotEmpty) {
      return data['results'][0]['formatted_address'];
    } else {
      throw Exception("Failed to fetch address.");
    }
  } catch (e) {
    print("Error fetching address: ${e.toString()}");
    return "Address not found"; // Return a default value instead of null
  }
}
