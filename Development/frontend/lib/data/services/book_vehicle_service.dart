import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/booking_vehicle_model.dart';

class BookVehicleService {
  final String baseUrl;

  BookVehicleService({required this.baseUrl});

  Future<List<BookingByVehicle>> fetchBookingsByVehicle(int vehicleId) async {
    final url = Uri.parse('$baseUrl/getBookingsByVehicle?vehicleId=$vehicleId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse['bookingByVehicle'] is List) {
          final bookVehicleJson = decodedResponse['bookingByVehicle'] as List;
          return bookVehicleJson
              .map((json) => BookingByVehicle.fromJson(json))
              .toList();
        } else {
          throw Exception("Error: 'bookingByVehicle' is not a List");
        }
      } else {
        throw Exception(
            'Failed to fetch bookings by vehicle: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch bookings by vehicle: $e');
    }
  }
}
