import 'dart:convert';

import '../models/book_list_model.dart';
import 'package:http/http.dart' as http;

class BookService {
  final String baseUrl;

  BookService({required this.baseUrl});

  Future<Booking> fetchBookings(int userId) async {
    final url = Uri.parse('$baseUrl/getSingleBooking?id=$userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse["booking"] == null) {
          return Booking();
        }

        final booking = jsonResponse["booking"];
        return Booking.fromJson(booking);
      }
    } catch (e) {
      print('Error fetching books: $e');
    }
    return Booking();
  }
}
