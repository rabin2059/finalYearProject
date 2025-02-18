import 'dart:convert';
import 'package:frontend/data/models/bus.dart';
import 'package:frontend/data/models/bus_model.dart' as models;
import 'package:http/http.dart' as http;

class BusService {
  final String baseUrl;

  BusService({required this.baseUrl});

  /// Fetch Buses from API
  Future<List<models.Bus>> getBuses() async {
    try {
      final uri = Uri.parse('$baseUrl/getVehicles');
      final response =
          await http.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Extract buses list safely
        if (jsonResponse["bus"] == null || jsonResponse["bus"].isEmpty) {
          throw Exception('No buses available at the moment.');
        }

        final List<dynamic> busList = jsonResponse["bus"];

        return busList.map((busJson) => models.Bus.fromJson(busJson)).toList();
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching buses: $e');
      throw Exception('Failed to fetch buses.');
    }
  }

  Future<Vehicle> getBus(int busId) async {
    try {
      final uri = Uri.parse('$baseUrl/getSingleVehicle?id=$busId');
      final response =
          await http.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Extract bus safely
        if (jsonResponse["vehicle"] == null) {
          throw Exception('No bus found with ID $busId.');
        }

        final busJson = jsonResponse["vehicle"];
        return Vehicle.fromJson(busJson);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching bus with ID $busId: $e');
      throw Exception('Failed to fetch bus.');
    }
  }
}
