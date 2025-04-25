import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants.dart';
import '../models/vehicle_details_model.dart';

class VehicleService {
  final String baseUrl;
  VehicleService({required this.baseUrl});

  Future<Vehicle> fetchVehicleDetails(int vehicleId) async {
    final uri = Uri.parse('$baseUrl/getVehicleDetails/$vehicleId');
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      // The endpoint wraps the Vehicle inside a "vehicle" key
      return Vehicle.fromJson(jsonResponse['vehicle'] as Map<String, dynamic>);
    } else {
      throw Exception(
          'Failed to load vehicle details: ${response.statusCode} – ${response.body}');
    }
  }
}
