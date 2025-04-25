import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/passenger_model.dart';

class PassengerService {
  final String baseUrl;
  PassengerService({required this.baseUrl});

  Future<PassengerData> fetchHomeData(int userId) async {
    final uri = Uri.parse('$baseUrl/passengerData?userId=$userId');
    final response = await http.get(uri, headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      return PassengerData.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to fetch home data: ${response.statusCode} - ${response.body}');
    }
  }
}
