import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/busStop.dart';
import '../routes/routes.dart';

class ApiService {
  final String baseUrl = '${Routes.route}';

  Future<List<Vehicle>> fetchVehicles() async {
    final response = await http.get(Uri.parse('$baseUrl/getVehicles'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((vehicle) => Vehicle.fromJson(vehicle)).toList();
    } else {
      throw Exception('Failed to fetch vehicles: ${response.statusCode}');
    }
  }
}