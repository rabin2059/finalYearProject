import 'dart:convert';

import '../models/all_user_model.dart';
import 'package:http/http.dart' as http;

class AdminService {
  final String baseUrl;

  AdminService({required this.baseUrl});

  Future<List<User>> getAllUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getAllUser'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final userList = (decoded['user'] as List)
            .map((userJson) => User.fromJson(userJson))
            .toList();
        return userList;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting users: $e');
    }
  }
}
