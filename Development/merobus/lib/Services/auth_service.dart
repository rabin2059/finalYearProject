import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  final String baseUrl;

  AuthService({required this.baseUrl});

  Future<Map<String, dynamic>> register(String username, String email,
      String password, String confirmPassword) async {
    try {
      final url = Uri.parse('${baseUrl}signUp');
      final body = {
        "username": username,
        "email": email,
        "password": password,
        "confirmPassword": confirmPassword
      };

      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final url = Uri.parse('${baseUrl}login');
      final body = {
        "email": email,
        "password": password,
      };

      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body));
      // print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Login Failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('An error occured: $e');
    }
  }

  // Check if the token is expired
  Future<bool> isTokenExpired(String token) async {
    try {
      // Decode the token and check expiration
      final isExpired = JwtDecoder.isExpired(token);
      return isExpired;
    } catch (e) {
      // Log the specific error for debugging
      print('Error decoding token: $e');
      return true; // Treat any error as the token being expired
    }
  }
}
