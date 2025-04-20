import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants.dart';
import '../models/driver_model.dart';

class DriverService {
  final String baseUrl;
  DriverService({required this.baseUrl});

  Future<DriverData> fetchHomeData(int userId) async {
    final uri = Uri.parse('$baseUrl/driverData?userId=$userId');
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      return DriverData.fromJson(jsonResponse);
    } else {
      throw Exception(
          'Failed to fetch driver data: ${response.statusCode} - ${response.body}');
    }
  }
}