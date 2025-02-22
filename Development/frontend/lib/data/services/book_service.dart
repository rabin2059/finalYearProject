import 'dart:convert';

import 'package:frontend/data/models/book_model.dart';

import '../models/book_list_model.dart';
import 'package:http/http.dart' as http;

class BookService {
  final String baseUrl;

  BookService({required this.baseUrl});

  Future<List<Booking>> fetchBookings(int userId) async {
    final url = Uri.parse('$baseUrl/getBookings?id=$userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);

        // ✅ Ensure 'booking' key exists & is a list
        if (decodedResponse['booking'] is List) {
          final bookListJson = decodedResponse['booking'] as List;
          return bookListJson.map((json) => Booking.fromJson(json)).toList();
        } else {
          throw Exception("Error: 'booking' is not a List");
        }
      } else {
        throw Exception(
            'Failed to fetch bookings: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching bookings: $e');
    }
  }

  Future<Book> getBook(int bookId) async {
    try {
      final uri = Uri.parse('$baseUrl/getSingleBooking?id=$bookId');
      final response =
          await http.get(uri, headers: {'Content-Type': 'application/json'});

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Extract bus safely
        if (jsonResponse["book"] == null) {
          throw Exception('No bus found with ID $bookId.');
        }

        return Book.fromJson(jsonResponse["book"]);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching bus with ID $bookId: $e');
      throw Exception('Failed to fetch bus.');
    }
  }
}
